import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io';

class NotificationDebugService {
  static final NotificationDebugService _instance =
      NotificationDebugService._internal();
  factory NotificationDebugService() => _instance;
  NotificationDebugService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Comprehensive notification system test
  Future<void> debugNotificationSystem() async {
    print('🔍 Starting comprehensive notification debug...');

    // 1. Check if notifications are enabled at system level
    await _checkSystemNotificationSettings();

    // 2. Check app permissions
    await _checkAppPermissions();

    // 3. Test notification plugin initialization
    await _testNotificationPluginInit();

    // 4. Test immediate notification
    await _testImmediateNotification();

    // 5. Test scheduled notification (30 seconds from now)
    await _testScheduledNotification();

    print('🔍 Notification debug completed.');
  }

  Future<void> _checkSystemNotificationSettings() async {
    print('\n📱 === SYSTEM NOTIFICATION SETTINGS ===');

    try {
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>();

        if (androidImplementation != null) {
          final bool? notificationsEnabled =
              await androidImplementation.areNotificationsEnabled();
          print('📱 System notifications enabled: $notificationsEnabled');

          if (notificationsEnabled == false) {
            print('⚠️ Notifications are disabled at system level!');
          }
        }
      } else {
        print('📱 iOS notification settings check not implemented');
      }
    } catch (e) {
      print('❌ Error checking system notification settings: $e');
    }
  }

  Future<void> _checkAppPermissions() async {
    print('\n🔐 === APP PERMISSIONS ===');

    try {
      // Check notification permission
      final PermissionStatus notificationStatus =
          await Permission.notification.status;
      print('🔐 Notification permission: $notificationStatus');

      if (notificationStatus.isDenied) {
        print('⚠️ Requesting notification permission...');
        final PermissionStatus result = await Permission.notification.request();
        print('🔐 Permission request result: $result');
      }

      // Check exact alarm permission for Android 12+
      if (Platform.isAndroid) {
        final PermissionStatus scheduleExactAlarmStatus =
            await Permission.scheduleExactAlarm.status;
        print('🔐 Schedule exact alarm permission: $scheduleExactAlarmStatus');

        if (scheduleExactAlarmStatus.isDenied) {
          print('⚠️ Requesting exact alarm permission...');
          final PermissionStatus result =
              await Permission.scheduleExactAlarm.request();
          print('🔐 Exact alarm permission result: $result');
        }
      }
    } catch (e) {
      print('❌ Error checking app permissions: $e');
    }
  }

  Future<void> _testNotificationPluginInit() async {
    print('\n🔧 === NOTIFICATION PLUGIN INITIALIZATION ===');

    try {
      // Initialize notification settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      final bool? initialized =
          await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          print('📱 Notification tapped: ${details.payload}');
        },
      );

      print('🔧 Plugin initialized: $initialized');

      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>();

        await androidImplementation?.createNotificationChannel(
          const AndroidNotificationChannel(
            'medication_reminders',
            'Medication Reminders',
            description: 'Notifications for medication reminders',
            importance: Importance.max,
            enableVibration: true,
            playSound: true,
          ),
        );

        print('🔧 Android notification channel created');
      }
    } catch (e) {
      print('❌ Error initializing notification plugin: $e');
    }
  }

  Future<void> _testImmediateNotification() async {
    print('\n⚡ === IMMEDIATE NOTIFICATION TEST ===');

    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'debug_immediate',
        'Debug Immediate',
        channelDescription: 'Debug immediate notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosPlatformChannelSpecifics =
          DarwinNotificationDetails(
        sound: 'default',
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        12345,
        'Debug Test',
        'Immediate notification test - ${DateTime.now()}',
        platformChannelSpecifics,
        payload: 'debug_immediate_test',
      );

      print('✅ Immediate notification sent successfully');
    } catch (e) {
      print('❌ Error sending immediate notification: $e');
    }
  }

  Future<void> _testScheduledNotification() async {
    print('\n⏰ === SCHEDULED NOTIFICATION TEST ===');

    try {
      final scheduledTime = DateTime.now().add(Duration(seconds: 30));
      print('📅 Scheduling notification for: $scheduledTime');

      // Initialize timezone data
      tz.initializeTimeZones();
      final location = tz.local;
      final tzDateTime = tz.TZDateTime.from(scheduledTime, location);

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'debug_scheduled',
        'Debug Scheduled',
        channelDescription: 'Debug scheduled notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosPlatformChannelSpecifics =
          DarwinNotificationDetails(
        sound: 'default',
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        54321,
        'Scheduled Test',
        'Scheduled notification test - fired at ${DateTime.now()}',
        tzDateTime,
        platformChannelSpecifics,
        payload: 'debug_scheduled_test',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('✅ Scheduled notification set for 30 seconds from now');
    } catch (e) {
      print('❌ Error scheduling notification: $e');
    }
  }

  Future<void> testMedicationReminder() async {
    print('\n💊 === MEDICATION REMINDER TEST (DUAL NOTIFICATIONS) ===');

    try {
      final scheduledTime =
          DateTime.now().add(Duration(minutes: 15)); // 15 minutes from now
      final reminderTime = scheduledTime.subtract(
          Duration(minutes: 10)); // 5 minutes from now (10 min before)

      print('💊 Testing dual notification system with proper timing:');
      print('💊 Reminder notification: ${reminderTime} (5 minutes from now)');
      print('💊 Main notification: ${scheduledTime} (15 minutes from now)');
      print('💊 Time gap: 10 minutes between notifications');
      print('💊 This ensures notifications are properly spaced apart');

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'medication_reminders',
        'Medication Reminders',
        channelDescription: 'Notifications for medication reminders',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosPlatformChannelSpecifics =
          DarwinNotificationDetails(
        sound: 'default',
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosPlatformChannelSpecifics,
      );

      // Initialize timezone data
      tz.initializeTimeZones();
      final location = tz.local;

      // Schedule reminder notification (1 minute from now)
      final reminderTzDateTime = tz.TZDateTime.from(reminderTime, location);
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        99998,
        'Medication Reminder',
        'Get ready! Take your test medication in 10 minutes',
        reminderTzDateTime,
        platformChannelSpecifics,
        payload: 'medication_reminder:test_id:reminder',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('✅ Reminder notification scheduled for 5 minutes from now');

      // Schedule main notification (15 minutes from now)
      final mainTzDateTime = tz.TZDateTime.from(scheduledTime, location);
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        99999,
        'Medication Time!',
        'Time to take your test medication NOW',
        mainTzDateTime,
        platformChannelSpecifics,
        payload: 'medication_reminder:test_id:main',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('✅ Main notification scheduled for 15 minutes from now');
      print('💊 Watch for notifications:');
      print('   📱 First notification in 5 minutes (reminder)');
      print('   📱 Second notification in 15 minutes (main)');
    } catch (e) {
      print('❌ Error scheduling dual medication reminders: $e');
    }
  }

  /// Check pending notifications
  Future<void> checkPendingNotifications() async {
    print('\n📋 === PENDING NOTIFICATIONS ===');

    try {
      final List<PendingNotificationRequest> pendingNotifications =
          await _flutterLocalNotificationsPlugin.pendingNotificationRequests();

      print('📋 Found ${pendingNotifications.length} pending notifications:');
      for (final notification in pendingNotifications) {
        print(
            '  - ID: ${notification.id}, Title: ${notification.title}, Body: ${notification.body}');
      }
    } catch (e) {
      print('❌ Error checking pending notifications: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    print('\n🗑️ === CANCELING ALL NOTIFICATIONS ===');

    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      print('✅ All notifications canceled');
    } catch (e) {
      print('❌ Error canceling notifications: $e');
    }
  }
}
