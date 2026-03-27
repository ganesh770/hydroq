import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_10y.dart' as tz;
import 'package:timezone/data/latest_10y.dart' as tz;
import '../models/models.dart';
import 'storage_service.dart';

@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse response) async {
  final profile = await StorageService().loadProfile();
  await NotificationService().scheduleReminders(profile);
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'hydroq_reminders';
  static const _channelIdMuted = 'hydroq_reminders_muted';
  static const _channelName = 'Water Reminders';
  static const _channelDesc = 'Reminders to drink water throughout the day';

  Future<void> init() async {
    // We only need the base initialization
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final profile = await StorageService().loadProfile();
        await scheduleReminders(profile);
      },
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const channelMuted = AndroidNotificationChannel(
      _channelIdMuted,
      '$_channelName (Muted)',
      description: 'Silent water reminders',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.createNotificationChannel(channelMuted);
  }

  Future<bool> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    
    // CRITICAL: We MUST request exact alarms, otherwise Android 14+ 
    // will delay 1-minute tests by 15+ minutes.
    await android?.requestExactAlarmsPermission();

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    return granted ?? true;
  }

  Future<void> scheduleReminders(UserProfile profile) async {
    await cancelAll();

    if (!profile.remindersEnabled) return;

    final now = DateTime.now();
    final intervalMin = profile.reminderIntervalMinutes;

    final List<DateTime> nextSlots = [];

    for (int dayOffset = -1; dayOffset < 3 && nextSlots.length < 3; dayOffset++) {
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

      if (sleepAt.isBefore(wakeAt) || sleepAt.isAtSameMomentAs(wakeAt)) {
        sleepAt = sleepAt.add(const Duration(days: 1));
      }

      DateTime slot = wakeAt.add(Duration(minutes: intervalMin));
      while (slot.isBefore(sleepAt)) {
        if (slot.isAfter(now)) {
          nextSlots.add(slot);
          if (nextSlots.length >= 3) break;
        }
        slot = slot.add(Duration(minutes: intervalMin));
      }
    }

    if (nextSlots.isEmpty) return;

    final channelId = profile.remindersMuted ? _channelIdMuted : _channelId;
    final channelName =
        profile.remindersMuted ? '$_channelName (Muted)' : _channelName;

    final notifDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: _channelDesc,
        importance: profile.remindersMuted ? Importance.low : Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF2979FF),
        enableVibration: !profile.remindersMuted,
        playSound: !profile.remindersMuted,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: !profile.remindersMuted,
      ),
    );

    final messages = [
      ('💧 Time to hydrate!', 'Your body needs water. Take a sip now!'),
      ('💧 Water break!', 'Stay on track with your daily goal.'),
      ('💧 Drink up!', 'A glass of water keeps dehydration away.'),
    ];

    for (int i = 0; i < nextSlots.length; i++) {
      final scheduledDate = nextSlots[i];
      final msg = messages[i % messages.length];
      
      // CRITICAL FIX: Bypass fragile local timezone strings (like "Asia/Kolkata")
      // which can throw invisible errors. Instead, convert the exact absolute local DateTime 
      // into a pure UTC TZDateTime ensuring exact, infallible epoch alignment.
      final utcDate = scheduledDate.toUtc();
      final tzDate = tz.TZDateTime.utc(
        utcDate.year,
        utcDate.month,
        utcDate.day,
        utcDate.hour,
        utcDate.minute,
        utcDate.second,
      );

      try {
        await _plugin.zonedSchedule(
          i + 1,
          msg.$1,
          msg.$2,
          tzDate,
          notifDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: null,
        );
      } catch (e) {
        debugPrint('HydroQ: Failed to schedule #${i + 1}: $e');
      }
    }
  }

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

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<bool> areNotificationsEnabled() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? true;
  }
}