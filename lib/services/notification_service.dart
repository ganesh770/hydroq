import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_10y.dart' as tzdata;
import '../models/models.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'hydroq_reminders';
  static const _channelName = 'Water Reminders';
  static const _channelDesc = 'Reminders to drink water throughout the day';

  static const _tzChannel = MethodChannel('com.hydroq/timezone');

  bool _tzInitialized = false;

  // ── Initialization ────────────────────────────────────────────────────────

  Future<void> init() async {
    // 1. Initialize timezone database
    tzdata.initializeTimeZones();

    // 2. Detect device timezone via platform channel
    try {
      final String tzName = await _tzChannel.invokeMethod('getTimeZone');
      tz.setLocalLocation(tz.getLocation(tzName));
      _tzInitialized = true;
      debugPrint('HydroQ TZ: Device timezone = $tzName');
    } catch (e) {
      // Fallback: compute offset-based timezone
      debugPrint('HydroQ TZ: Platform channel failed ($e), using offset fallback');
      _setTimezoneFromOffset();
    }

    // 3. Initialize notification plugin
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // 4. Create notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
  }

  /// Fallback: derive timezone from device's UTC offset
  void _setTimezoneFromOffset() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;

    // Find a timezone that matches the current offset
    for (final loc in tz.timeZoneDatabase.locations.values) {
      final tzNow = tz.TZDateTime.now(loc);
      if (tzNow.timeZoneOffset == offset) {
        tz.setLocalLocation(loc);
        _tzInitialized = true;
        debugPrint('HydroQ TZ: Using offset fallback = ${loc.name}');
        return;
      }
    }

    // Ultimate fallback: UTC
    tz.setLocalLocation(tz.UTC);
    _tzInitialized = true;
    debugPrint('HydroQ TZ: Using UTC fallback');
  }

  // ── Permissions ───────────────────────────────────────────────────────────

  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    // Request POST_NOTIFICATIONS (Android 13+)
    final granted = await android?.requestNotificationsPermission();

    // Request SCHEDULE_EXACT_ALARM (Android 14+)
    // This opens the system "Alarms & reminders" settings page
    await android?.requestExactAlarmsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    return granted ?? true;
  }

  /// Check if exact alarms are allowed (may be denied on Android 14+)
  Future<bool> canScheduleExactAlarms() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true; // iOS or unknown → assume yes

    // This calls AlarmManager.canScheduleExactAlarms() internally
    try {
      final pending = await _plugin.pendingNotificationRequests();
      // If we can query, the plugin is working. Check the actual permission:
      return await android.canScheduleExactNotifications() ?? true;
    } catch (e) {
      debugPrint('HydroQ: canScheduleExactAlarms check failed: $e');
      return false;
    }
  }

  // ── Scheduling ────────────────────────────────────────────────────────────

  Future<void> scheduleReminders(UserProfile profile) async {
    // Always cancel everything first
    await cancelAll();

    if (!profile.remindersEnabled) return;
    if (!_tzInitialized) {
      debugPrint('HydroQ: Timezone not initialized, cannot schedule');
      return;
    }

    final now = DateTime.now();
    final intervalMin = profile.reminderIntervalMinutes;
    final useExact = await canScheduleExactAlarms();

    debugPrint('HydroQ Schedule: interval=${intervalMin}min, exact=$useExact');

    // Calculate all future slots for today + tomorrow (up to 50)
    final List<DateTime> slots = [];

    for (int dayOffset = 0; dayOffset <= 1 && slots.length < 50; dayOffset++) {
      final baseDay = DateTime(now.year, now.month, now.day)
          .add(Duration(days: dayOffset));

      final wakeAt = DateTime(
        baseDay.year, baseDay.month, baseDay.day,
        profile.wakeTime.hour, profile.wakeTime.minute,
      );

      DateTime sleepAt = DateTime(
        baseDay.year, baseDay.month, baseDay.day,
        profile.sleepTime.hour, profile.sleepTime.minute,
      );

      // Handle overnight (sleep time is after midnight)
      if (sleepAt.isBefore(wakeAt) || sleepAt.isAtSameMomentAs(wakeAt)) {
        sleepAt = sleepAt.add(const Duration(days: 1));
      }

      // Generate slots at every interval between wake and sleep
      DateTime slot = wakeAt.add(Duration(minutes: intervalMin));
      while (slot.isBefore(sleepAt) && slots.length < 50) {
        if (slot.isAfter(now)) {
          slots.add(slot);
        }
        slot = slot.add(Duration(minutes: intervalMin));
      }
    }

    if (slots.isEmpty) {
      debugPrint('HydroQ: No future slots to schedule');
      return;
    }

    debugPrint('HydroQ: Scheduling ${slots.length} notifications');

    // Schedule mode: alarmClock is highest priority, inexact is fallback
    final scheduleMode = useExact
        ? AndroidScheduleMode.alarmClock
        : AndroidScheduleMode.inexactAllowWhileIdle;

    const notifDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF2979FF),
        enableVibration: true,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final messages = [
      ('💧 Time to hydrate!', 'Your body needs water. Take a sip now!'),
      ('💧 Water break!', 'Stay on track with your daily goal.'),
      ('💧 Drink up!', 'A glass of water keeps dehydration away.'),
      ('💧 Stay hydrated!', 'Remember to drink some water.'),
      ('💧 Hydration check!', 'Time for a refreshing glass of water.'),
    ];

    for (int i = 0; i < slots.length; i++) {
      final scheduledDate = slots[i];
      final msg = messages[i % messages.length];

      // CORRECT timezone conversion: TZDateTime.from() handles DST properly
      final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

      try {
        await _plugin.zonedSchedule(
          i + 1, // notification IDs 1..N
          msg.$1,
          msg.$2,
          tzDate,
          notifDetails,
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: null,
        );
      } catch (e) {
        debugPrint('HydroQ: Failed to schedule #${i + 1} at $scheduledDate: $e');
        // If exact alarm fails, retry with inexact
        if (useExact) {
          try {
            await _plugin.zonedSchedule(
              i + 1,
              msg.$1,
              msg.$2,
              tzDate,
              notifDetails,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              matchDateTimeComponents: null,
            );
            debugPrint('HydroQ: Fallback to inexact succeeded for #${i + 1}');
          } catch (e2) {
            debugPrint('HydroQ: Even inexact failed for #${i + 1}: $e2');
          }
        }
      }
    }

    debugPrint('HydroQ: Scheduling complete');
  }

  // ── Cancel ────────────────────────────────────────────────────────────────

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ── Goal reached notification ─────────────────────────────────────────────

  Future<void> showGoalReached() async {
    await _plugin.show(
      99,
      '🎉 Daily goal reached!',
      "Amazing! You've hit your water goal for today.",
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ── Status check ──────────────────────────────────────────────────────────

  Future<bool> areNotificationsEnabled() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? true;
  }

  /// Get count of currently pending notifications (for debug/UI)
  Future<int> getPendingCount() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.length;
  }
}