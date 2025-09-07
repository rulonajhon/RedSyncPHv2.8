import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/notification_service.dart';

class NotificationTestScreen extends StatefulWidget {
  @override
  _NotificationTestScreenState createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final NotificationService _notificationService = NotificationService();
  List<String> _testResults = [];
  bool _isLoading = false;

  void _addResult(String result) {
    setState(() {
      _testResults.add(result);
    });
  }

  Future<void> _runNotificationTest() async {
    setState(() {
      _isLoading = true;
      _testResults.clear();
    });

    try {
      _addResult('🧪 NOTIFICATION DIAGNOSTIC TEST');
      _addResult('================================');

      // Step 1: Initialize notifications
      _addResult('\n🔄 Step 1: Initializing notification service...');
      await _notificationService.initNotifications();
      _addResult('✅ Notification service initialized');

      // Step 2: Check pending notifications
      _addResult('\n🔄 Step 2: Checking existing pending notifications...');
      final pending = await _notificationService.getPendingNotifications();
      _addResult('📋 Found ${pending.length} pending notifications:');
      for (var notification in pending) {
        _addResult('   - ID: ${notification.id}, Title: ${notification.title}');
      }

      // Step 3: Clear all existing notifications
      _addResult('\n🧹 Step 3: Clearing all existing notifications...');
      await _notificationService.cancelAllNotifications();
      _addResult('✅ All notifications cleared');

      // Step 4: Test immediate notification (5 seconds)
      _addResult('\n🧪 Step 4: Testing 5-second notification...');
      await _notificationService.scheduleMedReminder(
        id: 999999,
        title: '🔔 RedSync Test',
        body: 'Hello! This is a friendly test notification from RedSync 😊',
        scheduledDate: DateTime.now().add(const Duration(seconds: 5)),
      );
      _addResult('✅ 5-second notification scheduled');

      // Step 5: Test 30-second notification
      _addResult('\n⏰ Step 5: Testing 30-second notification...');
      final thirtySecTime = DateTime.now().add(const Duration(seconds: 30));
      await _notificationService.scheduleMedReminder(
        id: 777777,
        title: '⏰ RedSync Reminder',
        body:
            'Hi! This is a gentle reminder test from your health companion 💙',
        scheduledDate: thirtySecTime,
      );
      _addResult(
          '✅ 30-second notification scheduled for: ${thirtySecTime.toString().substring(11, 19)}');

      // Step 6: Test 1-minute notification
      _addResult('\n⏰ Step 6: Testing 1-minute notification...');
      final oneMinuteTime = DateTime.now().add(const Duration(minutes: 1));
      await _notificationService.scheduleMedReminder(
        id: 777778,
        title: '💊 RedSync Health Care',
        body: 'Greetings! This is your caring health reminder from RedSync ❤️',
        scheduledDate: oneMinuteTime,
      );
      _addResult(
          '✅ 1-minute notification scheduled for: ${oneMinuteTime.toString().substring(11, 19)}');

      // Step 7: Verify notifications were scheduled
      _addResult('\n✅ Step 7: Verifying scheduled notifications...');
      final finalNotifications =
          await _notificationService.getPendingNotifications();
      _addResult(
          '📋 Final pending notifications: ${finalNotifications.length}');
      for (var notification in finalNotifications) {
        _addResult('   - ID: ${notification.id}, Title: ${notification.title}');
      }

      _addResult('\n🎯 NEXT STEPS:');
      _addResult(
          '1. Watch for notifications at 5 seconds, 30 seconds, and 1 minute');
      _addResult('2. If no notifications appear, check:');
      _addResult('   - Notification permissions in phone settings');
      _addResult('   - Battery optimization (disable for this app)');
      _addResult('   - Do Not Disturb mode');
      _addResult('   - App notification settings');
      _addResult('\n✅ Test complete! Watch your notification panel.');
    } catch (e) {
      _addResult('❌ ERROR: $e');
      _addResult('\n🔧 TROUBLESHOOTING:');
      _addResult('1. Ensure app has notification permissions');
      _addResult('2. Check if Do Not Disturb is enabled');
      _addResult('3. Verify app is not in battery optimization');
      _addResult('4. Try restarting the app');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testDeviceOptimization() async {
    try {
      _addResult('\n🔧 Testing device optimization access...');

      const platform = MethodChannel('ph.redsync/device_optimizations');

      await platform.invokeMethod('requestBatteryOptimizationExemption');
      _addResult('✅ Battery optimization exemption requested');

      await platform.invokeMethod('openNotificationSettings');
      _addResult('✅ Notification settings opened');
    } catch (e) {
      _addResult('❌ Device optimization error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🧪 Notification Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _runNotificationTest,
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('🧪 Run Notification Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _testDeviceOptimization,
                  child: Text('🔧'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  padding: EdgeInsets.all(8),
                  itemCount: _testResults.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 1),
                      child: Text(
                        _testResults[index],
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: _testResults[index].startsWith('❌')
                              ? Colors.red
                              : _testResults[index].startsWith('✅')
                                  ? Colors.green
                                  : Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              '📱 Keep this screen open and watch your notification panel',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
