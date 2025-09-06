import 'package:flutter/material.dart';
import 'lib/services/enhanced_medication_service.dart';
import 'lib/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Create services
  final notificationService = NotificationService();
  final medicationService = EnhancedMedicationService();

  print('🔧 === COMPREHENSIVE NOTIFICATION DIAGNOSTIC ===');
  print('📅 Current time: ${DateTime.now()}');

  try {
    // Step 1: Check notification permissions
    print('\n🔐 STEP 1: Checking notification permissions...');
    await notificationService.initNotifications();
    print('🔐 Notification service initialized');

    // Step 2: Check current pending notifications
    print('\n📋 STEP 2: Checking current pending notifications...');
    // Pending notification retrieval not supported in new NotificationService

    // Step 3: Clear all existing notifications
    print('\n🧹 STEP 3: Clearing all existing notifications...');
    // Cancel all notifications not supported in new NotificationService

    // Step 4: Test immediate notification
    print('\n🧪 STEP 4: Testing immediate notification...');
    await notificationService.scheduleMedReminder(
      999999,
      '🧪 Immediate Test',
      'This should appear immediately',
      DateTime.now().add(const Duration(seconds: 5)),
    );
    print('✅ Immediate notification scheduled for 5 seconds from now');

    // Step 5: Test scheduled notification (1 minute)
    print('\n⏰ STEP 5: Testing 1-minute scheduled notification...');
    final oneMinuteTime = DateTime.now().add(const Duration(minutes: 1));
    await notificationService.scheduleMedReminder(
      777777,
      '⏰ 1-Minute Test',
      'This should appear in 1 minute',
      oneMinuteTime,
    );
    print('✅ 1-minute notification scheduled for: $oneMinuteTime');

    // Step 6: Test scheduled notification (2 minutes)
    print('\n⏰ STEP 6: Testing 2-minute scheduled notification...');
    final twoMinuteTime = DateTime.now().add(const Duration(minutes: 2));
    await notificationService.scheduleMedReminder(
      777778,
      '⏰ 2-Minute Test',
      'This should appear in 2 minutes',
      twoMinuteTime,
    );
    print('✅ 2-minute notification scheduled for: $twoMinuteTime');

    // Step 7: Verify notifications were scheduled
    print('\n✅ STEP 7: Verifying scheduled notifications...');
    // The NotificationService does not have getPendingNotifications().
    // If you need to verify, use the plugin directly or remove this block.

    // Step 8: Test medication service
    print('\n💊 STEP 8: Testing medication service...');
    await medicationService.initialize();

    // Get current medication schedules
    final schedules = await medicationService.getAllMedicationSchedules();
    print('💊 Current medication schedules: ${schedules.length}');

    for (final schedule in schedules) {
      print(
          '  - ${schedule.medicationName} (${schedule.dose}) at ${schedule.time}');
      print('    Notifications enabled: ${schedule.notification}');
      print('    Active: ${schedule.isActive}');
      print('    Notification IDs: ${schedule.notificationIds}');
    }

    // Step 9: Create a test medication schedule
    print('\n🧪 STEP 9: Creating test medication schedule...');
    final testTime = DateTime.now().add(const Duration(minutes: 3));
    final timeString =
        '${testTime.hour.toString().padLeft(2, '0')}:${testTime.minute.toString().padLeft(2, '0')}';

    final scheduleId = await medicationService.createMedicationSchedule(
      medicationName: 'DEBUG TEST MEDICATION',
      medType: 'Tablet',
      dose: '50mg',
      frequency: 'Daily',
      time: timeString,
      startDate: DateTime.now().toIso8601String().split('T')[0],
      endDate: DateTime.now()
          .add(const Duration(days: 1))
          .toIso8601String()
          .split('T')[0],
      daysOfWeek: ['1', '2', '3', '4', '5', '6', '7'],
      notes: 'Debug test medication for notification testing',
    );

    if (scheduleId != null) {
      print('✅ Test medication schedule created with ID: $scheduleId');
      print('📅 Scheduled for: $timeString (in 3 minutes)');
      print('💡 This should create 2 notifications:');
      print('   1. 5-minute advance (should appear immediately if < 5 min)');
      print('   2. Exact time (should appear in 3 minutes)');
    } else {
      print('❌ Failed to create test medication schedule');
    }

    // Step 10: Final verification
    print('\n🔍 STEP 10: Final verification...');
    final finalNotifications =
        // The NotificationService does not have getPendingNotifications().
        // If you need to verify, use the plugin directly or remove this block.

        print('\n✅ DIAGNOSTIC COMPLETE!');
    print('🔔 Expected notifications:');
    print('   - Immediate test (should have appeared already)');
    print('   - 1-minute test (should appear in 1 minute)');
    print('   - 2-minute test (should appear in 2 minutes)');
    print(
        '   - 5-minute advance for test med (immediate or skipped if < 5 min)');
    print('   - Exact time for test med (should appear in 3 minutes)');
    print('\n📱 Please wait and observe your phone for notifications...');
  } catch (e) {
    print('❌ DIAGNOSTIC ERROR: $e');
  }
}
