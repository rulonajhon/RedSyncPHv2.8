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
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initNotifications() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();

      debugPrint(
          '🏥 [NATIVE SCHEDULING] Initializing like Facebook Messenger...');

      // Android initialization with NATIVE OS scheduling
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      // iOS initialization
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _plugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint("[Foreground] Notification tapped: ${response.payload}");
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      // Request essential permissions for NATIVE scheduling
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        debugPrint(
            '📱 [DEVICE] ${androidInfo.manufacturer} ${androidInfo.model} - Android ${androidInfo.version.release}');

        // Android 13+ notification permission
        if (androidInfo.version.sdkInt >= 33) {
          final status = await Permission.notification.status;
          if (!status.isGranted) {
            await Permission.notification.request();
          }
        }

        // Exact alarm permission for precise scheduling
        await Permission.scheduleExactAlarm.request();

        // OPPO-specific: Request battery optimization exemption
        if (androidInfo.manufacturer.toLowerCase().contains('oppo')) {
          debugPrint('🔋 [OPPO] Requesting battery optimization exemption...');
          await Permission.ignoreBatteryOptimizations.request();
        }
      }

      _initialized = true;
      debugPrint(
          '✅ [NATIVE SCHEDULING] Initialized successfully - notifications will be delivered by OS');
    } catch (e) {
      debugPrint('❌ [ERROR] Failed to initialize notifications: $e');
      throw Exception('Failed to initialize notifications: $e');
    }
  }

  /// Schedule medication reminder using NATIVE OS scheduling (like Facebook Messenger)
  Future<void> scheduleMedReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      await initNotifications();

      final tz.TZDateTime tzScheduledDate =
          tz.TZDateTime.from(scheduledDate, tz.local);

      debugPrint(
          '� [NATIVE SCHEDULE] Medication reminder for $tzScheduledDate');
      debugPrint('� [DETAILS] ID: $id, Title: $title');

      // HIGH PRIORITY notification details for medication reminders
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'medication_reminders',
        'RedSync Medication Reminders',
        channelDescription: 'Gentle reminders for your medication schedule',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        // Use default system notification sound instead of custom sound
        icon: '@mipmap/launcher_icon', // Small RedSync logo on the left like Facebook
        // No largeIcon for clean Facebook-style appearance
        // Enable native OS delivery even when app is closed
        ongoing: false,
        autoCancel: true,
        // Critical for OPPO devices
        fullScreenIntent: false,
        channelShowBadge: true,
        styleInformation: BigTextStyleInformation(''),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        categoryIdentifier: 'medication_reminder',
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule using NATIVE OS notification center (like Facebook Messenger)
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        details,
        payload: payload,
        // CRITICAL: Use exactAllowWhileIdle for reliable delivery
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // Match wake lock timeout for guaranteed delivery
        matchDateTimeComponents: null,
      );

      debugPrint(
          '✅ [STORED IN OS] Notification stored in phone notification center');
      debugPrint('🔔 [NATIVE] OS will deliver even when app is closed');
    } catch (e) {
      debugPrint('❌ [ERROR] Failed to schedule reminder: $e');
      throw Exception('Failed to schedule medication reminder: $e');
    }
  }

  /// Get all pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
    debugPrint(
        '🗑️ [CANCELLED] Notification $id removed from OS notification center');
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
    debugPrint(
        '�️ [CANCELLED ALL] All notifications removed from OS notification center');
  }

  /// Test notification for verification
  Future<void> pushTestNotification() async {
    await initNotifications();
    final now = DateTime.now();
    final testTime = now.add(const Duration(minutes: 2));

    await scheduleMedReminder(
      id: 999999,
      title: '🔔 RedSync Health Test',
      body:
          'Hello! This is a friendly test to confirm your RedSync notifications are working perfectly. Take care! 💙',
      scheduledDate: testTime,
      payload: 'test_notification',
    );

    debugPrint('✅ [TEST] Test notification scheduled for 2 minutes from now');
  }
}
