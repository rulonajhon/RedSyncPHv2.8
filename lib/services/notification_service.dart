import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  debugPrint("[Background] Notification tapped: ${response.payload}");
}

class NotificationService {
  /// Force a test notification to guarantee delivery
  Future<void> pushTestNotification() async {
    await initNotifications();
    final now = DateTime.now();
    final testTime = now.add(const Duration(minutes: 2));
    final tzTestTime = tz.TZDateTime.from(testTime, tz.local);
    debugPrint('🔔 [TEST] Scheduling fallback notification for $tzTestTime');
    const androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Critical notifications for medication reminders',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher', // fallback to default app icon
    );
    const iosDetails = DarwinNotificationDetails();
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _plugin.zonedSchedule(
      999999,
      '🚨 TEST NOTIFICATION',
      'This is a guaranteed test notification. If you see this, notifications are working.',
      tzTestTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    debugPrint('✅ [TEST] Fallback notification scheduled for $tzTestTime');
  }

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initNotifications() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    // Android 13+ POST_NOTIFICATIONS permission
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        final status = await Permission.notification.status;
        if (!status.isGranted) {
          await Permission.notification.request();
        }
      }
    }

    const androidSettings =
        AndroidInitializationSettings('@drawable/notification_icon');
    const iosSettings = DarwinInitializationSettings();
    final settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint("[Foreground] Notification tapped: ${response.payload}");
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create channel for Android
    if (Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        const channel = AndroidNotificationChannel(
          'medication_reminders',
          'Medication Reminders',
          description: 'Critical notifications for medication reminders',
          importance: Importance.max,
        );
        await androidImpl.createNotificationChannel(channel);
      }
    }
    _initialized = true;
  }

  Future<void> scheduleMedReminder(
    int id,
    String title,
    String body,
    DateTime scheduledTime, {
    bool daily = false,
  }) async {
    await initNotifications();
    final now = DateTime.now();
    final localScheduled = scheduledTime.toLocal();
    final diff = localScheduled.difference(now);
    debugPrint(
        '🔔 [DEBUG] scheduleMedReminder called with: id=$id, title=$title, body=$body, scheduledTime=$scheduledTime, daily=$daily');
    final tzScheduled = tz.TZDateTime.from(localScheduled, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Critical notifications for medication reminders',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@drawable/notification_icon',
    );
    const iosDetails = DarwinNotificationDetails();
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: daily ? DateTimeComponents.time : null,
      );
      debugPrint('✅ Scheduled notification: $title at $tzScheduled');
    } catch (e, stack) {
      debugPrint('❌ [ERROR] Failed to schedule notification: $e');
      debugPrint('❌ [ERROR] Stack trace: $stack');
    }
  }
}
