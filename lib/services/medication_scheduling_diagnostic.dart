import 'enhanced_medication_service.dart';
import 'notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class MedicationSchedulingDiagnostic {
  static final MedicationSchedulingDiagnostic _instance =
      MedicationSchedulingDiagnostic._internal();
  factory MedicationSchedulingDiagnostic() => _instance;
  MedicationSchedulingDiagnostic._internal();

  final EnhancedMedicationService _enhancedMedicationService =
      EnhancedMedicationService();
  final NotificationService _notificationService = NotificationService();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Test the EXACT same flow as schedule_medication_screen.dart
  Future<Map<String, dynamic>> testFullMedicationSchedulingFlow() async {
    print('🔍 === TESTING FULL MEDICATION SCHEDULING FLOW ===');

    Map<String, dynamic> results = {
      'steps': [],
      'errors': [],
      'notifications_scheduled': 0,
      'pending_notifications': [],
    };

    try {
      // Step 1: Initialize Enhanced Medication Service (same as screen)
      results['steps']
          .add('Step 1: Initializing Enhanced Medication Service...');
      print('🔄 Step 1: Initializing Enhanced Medication Service...');

      await _enhancedMedicationService.initialize();
      results['steps'].add('✅ Enhanced Medication Service initialized');
      print('✅ Enhanced Medication Service initialized');

      // Step 2: Create medication schedule with EXACT same parameters as screen
      results['steps'].add('Step 2: Creating medication schedule...');
      print('🔄 Step 2: Creating medication schedule...');

      final now = DateTime.now();
      final testTime =
          TimeOfDay.fromDateTime(now.add(const Duration(minutes: 2)));

      final scheduleId =
          await _enhancedMedicationService.createMedicationSchedule(
        medicationName: 'TEST VIAGRA',
        medType: 'IV Injection',
        dose: '25mg',
        frequency: 'Daily',
        time:
            '${testTime.hour.toString().padLeft(2, '0')}:${testTime.minute.toString().padLeft(2, '0')}',
        startDate: now.toIso8601String().split('T')[0],
        endDate:
            now.add(const Duration(days: 2)).toIso8601String().split('T')[0],
        daysOfWeek: ['1', '2', '3', '4', '5', '6', '7'], // EXACT same as screen
        notes: 'Test medication scheduling',
      );

      if (scheduleId != null) {
        results['steps'].add('✅ Schedule created with ID: $scheduleId');
        print('✅ Schedule created with ID: $scheduleId');

        // Step 3: Check what notifications were actually scheduled
        results['steps'].add('Step 3: Checking scheduled notifications...');
        print('🔄 Step 3: Checking scheduled notifications...');

        final pendingNotifications = await _flutterLocalNotificationsPlugin
            .pendingNotificationRequests();

        // Filter for our test notifications
        final testNotifications = pendingNotifications.where((notification) {
          return notification.title?.contains('TEST VIAGRA') == true ||
              notification.body?.contains('TEST VIAGRA') == true ||
              notification.title?.contains('Medication Reminder') == true;
        }).toList();

        results['notifications_scheduled'] = testNotifications.length;
        results['pending_notifications'] = testNotifications
            .map((n) => {
                  'id': n.id,
                  'title': n.title,
                  'body': n.body,
                  'payload': n.payload,
                })
            .toList();

        results['steps'].add(
            '📱 Found ${testNotifications.length} pending medication notifications');
        print(
            '📱 Found ${testNotifications.length} pending medication notifications');

        for (final notification in testNotifications) {
          print('   📅 ID: ${notification.id}');
          print('   📝 Title: ${notification.title}');
          print('   📝 Body: ${notification.body}');
          print('   📦 Payload: ${notification.payload}');
          print('   ---');
        }

        // Step 4: Test direct notification scheduling
        results['steps']
            .add('Step 4: Testing direct notification scheduling...');
        print('🔄 Step 4: Testing direct notification scheduling...');

        await _notificationService.initNotifications();

        final directTestTime = DateTime.now().add(const Duration(minutes: 1));
        await _notificationService.scheduleMedReminder(
          99999,
          '💊 DIRECT TEST: Medication Reminder',
          'Direct scheduling test - TEST VIAGRA',
          directTestTime,
        );

        results['steps'].add(
            '✅ Direct notification scheduled for ${directTestTime.toString().substring(11, 19)}');
        print(
            '✅ Direct notification scheduled for ${directTestTime.toString().substring(11, 19)}');

        // Step 5: Final check of all pending notifications
        results['steps'].add('Step 5: Final notification count...');
        print('🔄 Step 5: Final notification count...');

        final finalPending = await _flutterLocalNotificationsPlugin
            .pendingNotificationRequests();
        results['steps']
            .add('📊 Total pending notifications: ${finalPending.length}');
        print('📊 Total pending notifications: ${finalPending.length}');
      } else {
        results['errors'].add('❌ Failed to create medication schedule');
        print('❌ Failed to create medication schedule');
      }
    } catch (e) {
      results['errors'].add('❌ Error in flow: $e');
      print('❌ Error in flow: $e');
    }

    return results;
  }

  /// Test weekday matching logic
  Future<void> testWeekdayLogic() async {
    print('\n🗓️ === TESTING WEEKDAY LOGIC ===');

    final now = DateTime.now();
    final weekdayFromDart = now.weekday; // 1-7 (Mon-Sun)
    final daysOfWeekFromScreen = ['1', '2', '3', '4', '5', '6', '7'];

    print('📅 Current date: ${now.toString().substring(0, 10)}');
    print('📅 Dart weekday: $weekdayFromDart');
    print('📅 Days from screen: $daysOfWeekFromScreen');
    print(
        '📅 Contains check: ${daysOfWeekFromScreen.contains(weekdayFromDart.toString())}');

    // Test for next few days
    for (int i = 0; i < 7; i++) {
      final testDate = now.add(Duration(days: i));
      final testWeekday = testDate.weekday;
      final isIncluded = daysOfWeekFromScreen.contains(testWeekday.toString());
      print(
          '📅 ${testDate.toString().substring(0, 10)} (weekday $testWeekday): ${isIncluded ? "✅ INCLUDED" : "❌ EXCLUDED"}');
    }
  }

  /// Test time parsing logic
  Future<void> testTimeLogic() async {
    print('\n⏰ === TESTING TIME LOGIC ===');

    final now = DateTime.now();
    final testTime =
        TimeOfDay.fromDateTime(now.add(const Duration(minutes: 2)));
    final timeString =
        '${testTime.hour.toString().padLeft(2, '0')}:${testTime.minute.toString().padLeft(2, '0')}';

    print('⏰ Current time: ${now.toString().substring(11, 19)}');
    print('⏰ Test time: $timeString');

    // Parse like the enhanced service does
    final timeParts = timeString.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    print('⏰ Parsed hour: $hour');
    print('⏰ Parsed minute: $minute');

    // Create schedule time like the service does
    final scheduleDate = DateTime(now.year, now.month, now.day, hour, minute);
    print('⏰ Schedule date: ${scheduleDate.toString()}');
    print('⏰ Is after now: ${scheduleDate.isAfter(now)}');

    // Test 10-minute reminder
    final reminderTime = scheduleDate.subtract(const Duration(minutes: 10));
    print('⏰ Reminder time: ${reminderTime.toString()}');
    print('⏰ Reminder is after now: ${reminderTime.isAfter(now)}');
  }

  /// Clean up test notifications
  Future<void> cleanupTestNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(99999);

      // Clean up any notifications with TEST VIAGRA
      final pending =
          await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      for (final notification in pending) {
        if (notification.title?.contains('TEST VIAGRA') == true ||
            notification.body?.contains('TEST VIAGRA') == true) {
          await _flutterLocalNotificationsPlugin.cancel(notification.id);
        }
      }

      print('🧹 Test notifications cleaned up');
    } catch (e) {
      print('⚠️ Cleanup error: $e');
    }
  }
}
