import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import '../services/device_optimization_service.dart';

class DebugReleaseHelper {
  static void showBuildModeInfo(BuildContext context) {
    final isDebug = kDebugMode;
    final isRelease = kReleaseMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Build Mode Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🔧 Build Mode: ${isDebug ? "DEBUG" : "RELEASE"}'),
            SizedBox(height: 8),
            Text('Debug Features:'),
            Text('• More verbose logging'),
            Text('• Hot reload enabled'),
            Text('• Debug banner visible'),
            Text('• Lenient notification scheduling'),
            SizedBox(height: 8),
            Text('Release Features:'),
            Text('• Optimized performance'),
            Text('• Aggressive notification settings'),
            Text('• Device-specific optimizations'),
            Text('• Battery optimization bypass'),
            SizedBox(height: 8),
            if (isRelease) ...[
              Text('⚠️ Release Mode Active:'),
              Text('• Notifications use aggressive settings'),
              Text('• Xiaomi optimizations enabled'),
              Text('• Background execution prioritized'),
            ] else ...[
              Text('🔧 Debug Mode Active:'),
              Text('• Relaxed notification constraints'),
              Text('• Enhanced debugging output'),
              Text('• Development permissions'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
          if (isRelease)
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await DeviceOptimizationService.handleAllDeviceOptimizations();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Requested device optimizations')),
                );
              },
              child: Text('Optimize Device'),
            ),
        ],
      ),
    );
  }

  static void scheduleTestNotification() async {
    final notificationService = NotificationService();
    final testTime = DateTime.now().add(Duration(minutes: 1));

    await notificationService.scheduleMedReminder(
      id: 999999,
      title: '🔔 RedSync Test',
      body: kDebugMode
          ? 'Hello! This is a friendly debug test from RedSync 😊'
          : 'Greetings! This is a polite release test from your health companion 💙',
      scheduledDate: testTime,
    );

    debugPrint(
        '🧪 [TEST] Scheduled ${kDebugMode ? "DEBUG" : "RELEASE"} test notification for $testTime');
  }
}
