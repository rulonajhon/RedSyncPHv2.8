import 'dart:io';
import 'lib/services/notification_service.dart';

void main() async {
  print('🧪 NOTIFICATION DIAGNOSTIC TEST');
  print('================================');

  final notificationService = NotificationService();

  try {
    // Step 1: Initialize notifications
    print('\n🔄 Step 1: Initializing notification service...');
    await notificationService.initNotifications();
    print('✅ Notification service initialized');

    // Step 2: Check pending notifications
    print('\n🔄 Step 2: Checking existing pending notifications...');
    final pending = await notificationService.getPendingNotifications();
    print('📋 Found ${pending.length} pending notifications:');
    for (var notification in pending) {
      print('   - ID: ${notification.id}, Title: ${notification.title}');
      print('     Body: ${notification.body}');
      print('   ---');
    }

    // Step 3: Clear all existing notifications
    print('\n🧹 Step 3: Clearing all existing notifications...');
    await notificationService.cancelAllNotifications();
    print('✅ All notifications cleared');

    // Step 4: Test immediate notification
    print('\n🧪 Step 4: Testing immediate notification...');
    await notificationService.scheduleMedReminder(
      id: 999999,
      title: '🧪 Immediate Test',
      body: 'This should appear immediately',
      scheduledDate: DateTime.now().add(const Duration(seconds: 5)),
    );
    print('✅ Immediate notification scheduled for 5 seconds from now');

    // Step 5: Test scheduled notification (1 minute)
    print('\n⏰ Step 5: Testing 1-minute scheduled notification...');
    final oneMinuteTime = DateTime.now().add(const Duration(minutes: 1));
    await notificationService.scheduleMedReminder(
      id: 777777,
      title: '⏰ 1-Minute Test',
      body: 'This should appear in 1 minute',
      scheduledDate: oneMinuteTime,
    );
    print('✅ 1-minute notification scheduled for: $oneMinuteTime');

    // Step 6: Test scheduled notification (2 minutes)
    print('\n⏰ Step 6: Testing 2-minute scheduled notification...');
    final twoMinuteTime = DateTime.now().add(const Duration(minutes: 2));
    await notificationService.scheduleMedReminder(
      id: 777778,
      title: '⏰ 2-Minute Test',
      body: 'This should appear in 2 minutes',
      scheduledDate: twoMinuteTime,
    );
    print('✅ 2-minute notification scheduled for: $twoMinuteTime');

    // Step 7: Verify notifications were scheduled
    print('\n✅ Step 7: Verifying scheduled notifications...');
    final finalNotifications =
        await notificationService.getPendingNotifications();
    print('📋 Final pending notifications: ${finalNotifications.length}');
    for (var notification in finalNotifications) {
      print('   - ID: ${notification.id}, Title: ${notification.title}');
    }

    print('\n🎯 NEXT STEPS:');
    print(
        '1. Watch for notifications to appear in 5 seconds, 1 minute, and 2 minutes');
    print('2. If no notifications appear, check device settings:');
    print('   - Notification permissions');
    print('   - Battery optimization (disable for this app)');
    print('   - Do Not Disturb mode');
    print('   - App notification settings');
    print('\n✅ Diagnostic complete! Check your phone for notifications.');
  } catch (e) {
    print('❌ ERROR: $e');
    print('\n🔧 TROUBLESHOOTING:');
    print('1. Ensure app has notification permissions');
    print('2. Check if Do Not Disturb is enabled');
    print('3. Verify app is not in battery optimization');
    print('4. Restart the app and try again');
  }
}
