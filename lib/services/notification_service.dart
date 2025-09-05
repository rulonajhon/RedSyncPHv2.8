import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Add a navigation callback for handling notification taps
  static void Function(String)? _onNotificationTap;

  // Set the callback for handling notification navigation
  static void setNavigationCallback(void Function(String) callback) {
    _onNotificationTap = callback;
  }

  Future<void> initialize() async {
    try {
      if (_isInitialized) {
        print('🔄 Notification service already initialized');
        return;
      }

      print('🔄 Initializing notification service...');

      // Initialize timezone data safely
      try {
        tz.initializeTimeZones();
        print('✅ Timezone data initialized');
      } catch (e) {
        print('⚠️ Warning: Could not initialize timezone data: $e');
      }

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@drawable/notification_icon');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
        defaultPresentAlert: true,
        defaultPresentSound: true,
        defaultPresentBadge: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          try {
            print('📱 Notification tapped: ${response.payload}');
            _handleNotificationTap(response);
          } catch (e) {
            print('❌ Error handling notification tap: $e');
          }
        },
      );

      // Create notification channels for Android
      await _createNotificationChannels();

      // Request permissions
      try {
        await requestPermissions();
        print('✅ Notification permissions requested');
      } catch (e) {
        print('⚠️ Warning: Could not request notification permissions: $e');
      }

      _isInitialized = true;
      print('✅ Notification service initialized successfully');
    } catch (e) {
      print('❌ Error initializing notification service: $e');
      _isInitialized = true;
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    try {
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>();

        if (androidImplementation != null) {
          print('📱 Creating Android notification channels...');

          // Medication reminders channel
          const AndroidNotificationChannel medicationChannel =
              AndroidNotificationChannel(
            'medication_reminders',
            'Medication Reminders',
            description: 'Critical notifications for medication reminders',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            showBadge: true,
          );

          await androidImplementation
              .createNotificationChannel(medicationChannel);

          print('✅ Android notification channels created successfully');
        }
      }
    } catch (e) {
      print('⚠️ Warning: Could not create notification channels: $e');
    }
  }

  void _handleNotificationTap(NotificationResponse response) {
    try {
      final payload = response.payload;
      if (payload != null) {
        print('Notification tapped with payload: $payload');

        if (_onNotificationTap != null) {
          _onNotificationTap!(payload);
        } else {
          print('No navigation callback set for notification handling');
        }
      }
    } catch (e) {
      print('Error in notification tap handler: $e');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        // Request notification permission
        await Permission.notification.request();
        
        // For Android 12+, also request exact alarm permission
        if (await Permission.scheduleExactAlarm.isDenied) {
          await Permission.scheduleExactAlarm.request();
        }
      }
      
      return true;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  Future<bool> _checkNotificationPermissions() async {
    try {
      if (Platform.isAndroid) {
        final notificationStatus = await Permission.notification.status;
        final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
        
        print('📱 Notification permission: $notificationStatus');
        print('⏰ Exact alarm permission: $exactAlarmStatus');
        
        return notificationStatus.isGranted && exactAlarmStatus.isGranted;
      }
      return true; // iOS permissions handled during initialization
    } catch (e) {
      print('⚠️ Error checking notification permissions: $e');
      return false;
    }
  }

  Future<void> scheduleMedicationReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      print('🔔 === SCHEDULING MEDICATION REMINDER ===');
      print('📅 ID: $id');
      print('📅 Title: $title');
      print('📅 Body: $body');
      print('📅 Scheduled for: $scheduledTime');
      print('📅 Current time: ${DateTime.now()}');

      // Check permissions
      print('🔐 Checking notification permissions...');
      final permissionsGranted = await _checkNotificationPermissions();
      print('🔐 Permissions granted: $permissionsGranted');

      if (!permissionsGranted) {
        print('⚠️ Notification permissions not granted, attempting to request...');
        await requestPermissions();
      }

      // Validate inputs
      if (title.isEmpty || body.isEmpty) {
        print('⚠️ Warning: Notification title or body is empty');
        return;
      }

      if (scheduledTime.isBefore(DateTime.now())) {
        print('❌ Error: Scheduled time is in the past: $scheduledTime');
        print('❌ Current time: ${DateTime.now()}');
        print('❌ Skipping notification scheduling');
        return;
      }

      // Create notification details with RedSync logo
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'medication_reminders',
        'Medication Reminders',
        channelDescription: 'Critical notifications for medication reminders',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@drawable/notification_icon', // Use RedSync logo
        enableVibration: true,
        playSound: true,
        autoCancel: false,
        ongoing: false,
        showWhen: true,
        enableLights: true,
        channelShowBadge: true,
        fullScreenIntent: false,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
      );

      const DarwinNotificationDetails iosPlatformChannelSpecifics =
          DarwinNotificationDetails(
        sound: 'default',
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: 1,
        categoryIdentifier: 'medication_reminder',
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosPlatformChannelSpecifics,
      );

      // Convert to timezone
      print('🌍 Converting to timezone...');
      tz.TZDateTime tzDateTime;
      try {
        tzDateTime = _convertToTZDateTime(scheduledTime);
        print('🌍 Timezone conversion successful: $tzDateTime');
      } catch (e) {
        print('❌ Timezone conversion failed: $e');
        print('🔄 Trying immediate notification as fallback...');

        await _flutterLocalNotificationsPlugin.show(
          id,
          title,
          body,
          platformChannelSpecifics,
          payload: payload,
        );
        print('✅ Immediate notification sent as fallback');
        return;
      }

      print('📅 Final scheduled time: $tzDateTime');
      print('⏰ Time difference: ${scheduledTime.difference(DateTime.now()).inMinutes} minutes');

      // Schedule the notification
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      print('✅ Notification scheduled successfully!');

      // Verify the notification was scheduled
      final pendingNotifications =
          await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      final ourNotification =
          pendingNotifications.where((n) => n.id == id).firstOrNull;
      if (ourNotification != null) {
        print('✅ Verification: Notification found in pending list');
      } else {
        print('⚠️ Warning: Notification not found in pending list');
      }
    } catch (e) {
      print('❌ Critical error scheduling medication reminder: $e');
      
      // Try immediate notification as last resort
      try {
        print('🔄 Attempting immediate notification as last resort...');
        await _flutterLocalNotificationsPlugin.show(
          id,
          title,
          '$body (Immediate fallback)',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'medication_reminders',
              'Medication Reminders',
              importance: Importance.max,
              priority: Priority.max,
              icon: '@drawable/notification_icon',
            ),
          ),
          payload: payload,
        );
        print('✅ Fallback notification sent');
      } catch (fallbackError) {
        print('❌ Even fallback notification failed: $fallbackError');
      }
    }
  }

  /// Convert DateTime to TZDateTime with timezone handling
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    try {
      final location = tz.local;
      return tz.TZDateTime.from(dateTime, location);
    } catch (e) {
      print('⚠️ Timezone conversion error: $e, using UTC');
      return tz.TZDateTime.utc(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        dateTime.hour,
        dateTime.minute,
        dateTime.second,
      );
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      print('❌ Error getting pending notifications: $e');
      return [];
    }
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Send immediate notification for testing
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'medication_reminders',
        'Medication Reminders',
        channelDescription: 'Test notifications',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@drawable/notification_icon',
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        999999, // Use a high ID for test notifications
        title,
        body,
        notificationDetails,
        payload: payload ?? 'test_notification',
      );

      print('✅ Immediate test notification sent: $title');
    } catch (e) {
      print('❌ Error sending immediate notification: $e');
    }
  }
}
