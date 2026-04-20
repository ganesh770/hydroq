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

  static const _nativeChannel = MethodChannel('com.ganesh_nagireddy.hydroq/reminder');

  /// Last scheduling result for UI display
  int lastScheduledCount = 0;

  // ── Initialization ──────────────────────────────────────────────────────

  Future<void> init() async {
    // 1. Initialize timezone database
    tzdata.initializeTimeZones();

    // 2. Set local timezone from device offset (no MethodChannel needed)
    _setTimezoneFromOffset();

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

  /// Derive timezone from device's UTC offset — works on every phone
  void _setTimezoneFromOffset() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;

    for (final loc in tz.timeZoneDatabase.locations.values) {
      final tzNow = tz.TZDateTime.now(loc);
      if (tzNow.timeZoneOffset == offset) {
        tz.setLocalLocation(loc);
        debugPrint('HydroQ TZ: ${loc.name}');
        return;
      }
    }
    // Ultimate fallback
    tz.setLocalLocation(tz.UTC);
    debugPrint('HydroQ TZ: UTC fallback');
  }

  // ── Permissions ─────────────────────────────────────────────────────────

  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    // Only request POST_NOTIFICATIONS (Android 13+)
    // Do NOT call requestExactAlarmsPermission() — it opens system settings
    // and never returns on some OEMs like iQOO/Vivo, hanging the toggle.
    final granted = await android?.requestNotificationsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    return granted ?? true;
  }

  // ── Scheduling ──────────────────────────────────────────────────────────

  /// Schedules reminders between wake and sleep time.
  /// Returns the number of notifications successfully scheduled.
  Future<int> scheduleReminders(UserProfile profile) async {
    await cancelAll();
    lastScheduledCount = 0;

    if (!profile.remindersEnabled) return 0;

    // Call the reference-app implementation natively.
    // The native code schedules a single continuous repeating alarm that checks boundaries automatically.
    try {
      await _nativeChannel.invokeMethod('scheduleNext');
      debugPrint('HydroQ: Background repeating alarm initialized via reference app method.');
      lastScheduledCount = 1; // 1 infinite alarm
    } catch (e) {
      debugPrint('HydroQ: Native background repeating alarm failed: $e');
    }

    return lastScheduledCount;
  }

  // ── Cancel ──────────────────────────────────────────────────────────────

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    lastScheduledCount = 0;
    try {
      await _nativeChannel.invokeMethod('cancelAlarm');
    } catch (_) {}
  }

  // ── Goal reached ────────────────────────────────────────────────────────

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

  // ── Status ──────────────────────────────────────────────────────────────

  Future<bool> areNotificationsEnabled() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? true;
  }

  Future<int> getPendingCount() async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return pending.length;
    } catch (e) {
      return lastScheduledCount;
    }
  }
}