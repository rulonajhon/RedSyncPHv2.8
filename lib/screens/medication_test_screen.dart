import 'package:flutter/material.dart';
import '../services/enhanced_medication_service.dart';

class MedicationTestScreen extends StatefulWidget {
  const MedicationTestScreen({super.key});

  @override
  State<MedicationTestScreen> createState() => _MedicationTestScreenState();
}

class _MedicationTestScreenState extends State<MedicationTestScreen> {
  final EnhancedMedicationService _enhancedMedicationService =
      EnhancedMedicationService();
  bool _isLoading = false;
  String _lastTestResult = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Medication Service Test'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🧪 Enhanced Medication Service Test',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Test the enhanced medication service with offline/online sync capabilities and 5-minute advance notifications.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testCreateMedication,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.medication),
              label: Text(_isLoading
                  ? 'Creating Test Medication...'
                  : 'Create Test Medication with 5-min Reminder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testSyncMedications,
              icon: const Icon(Icons.sync),
              label: const Text(
                  'Test Sync Medications (Clear Hive, Download Firebase)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testGetAllMedications,
              icon: const Icon(Icons.list),
              label: const Text('Get All Medications from Hive'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📝 Test Results:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _lastTestResult.isEmpty
                                ? 'No tests run yet. Click a button above to test the enhanced medication service.'
                                : _lastTestResult,
                            style: const TextStyle(
                                fontFamily: 'monospace', fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testCreateMedication() async {
    setState(() {
      _isLoading = true;
      _lastTestResult = '🔄 Starting medication creation test...\n';
    });

    try {
      // Initialize the service
      await _enhancedMedicationService.initialize();
      _updateResult('✅ Enhanced medication service initialized\n');

      // Create a test medication with 5-minute reminder
      final now = DateTime.now();
      final startDate = now;
      final endDate = now.add(const Duration(days: 3));
      final testTime = now.add(
          const Duration(minutes: 2)); // 2 minutes from now for quick testing

      final scheduleId =
          await _enhancedMedicationService.createMedicationSchedule(
        medicationName: 'Test Aspirin',
        medType: 'Oral',
        dose: '100mg',
        frequency: 'Daily',
        startDate: startDate.toIso8601String().split('T')[0],
        endDate: endDate.toIso8601String().split('T')[0],
        time:
            '${testTime.hour.toString().padLeft(2, '0')}:${testTime.minute.toString().padLeft(2, '0')}',
        daysOfWeek: ['1', '2', '3', '4', '5', '6', '7'], // All days
        notes: 'Test medication with 5-minute advance notification',
      );

      if (scheduleId != null) {
        _updateResult('✅ Test medication created successfully!\n');
        _updateResult('🆔 Schedule ID: $scheduleId\n');
        _updateResult(
            '⏰ Scheduled for: ${testTime.hour.toString().padLeft(2, '0')}:${testTime.minute.toString().padLeft(2, '0')}\n');
        _updateResult(
            '📱 5-minute reminder will be sent at: ${testTime.subtract(const Duration(minutes: 5)).toString()}\n');
        _updateResult(
            '💊 Exact time notification will be sent at: ${testTime.toString()}\n');
        _updateResult(
            '🔄 Check your phone notifications in the next few minutes!\n');
      } else {
        _updateResult('❌ Failed to create test medication\n');
      }
    } catch (e) {
      _updateResult('❌ Error during medication creation test: $e\n');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testSyncMedications() async {
    setState(() {
      _isLoading = true;
      _lastTestResult = '🔄 Starting medication sync test...\n';
    });

    try {
      await _enhancedMedicationService.initialize();
      _updateResult('✅ Enhanced medication service initialized\n');

      await _enhancedMedicationService.syncMedicationSchedules();
      _updateResult('✅ Medication sync completed!\n');
      _updateResult('🗑️ All local medications cleared from Hive\n');
      _updateResult('⬇️ All medications downloaded from Firebase\n');
      _updateResult('📱 Notifications rescheduled for all medications\n');
    } catch (e) {
      _updateResult('❌ Error during sync test: $e\n');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetAllMedications() async {
    setState(() {
      _isLoading = true;
      _lastTestResult = '🔄 Getting all medications from Hive...\n';
    });

    try {
      final medications =
          await _enhancedMedicationService.getAllMedicationSchedules();
      _updateResult(
          '✅ Retrieved ${medications.length} medications from Hive\n\n');

      if (medications.isEmpty) {
        _updateResult('📭 No medications found in local storage\n');
        _updateResult(
            '💡 Try creating a test medication or syncing from Firebase\n');
      } else {
        for (int i = 0; i < medications.length; i++) {
          final med = medications[i];
          _updateResult('💊 Medication ${i + 1}:\n');
          _updateResult('   📝 Name: ${med.medicationName}\n');
          _updateResult('   💉 Type: ${med.medType}\n');
          _updateResult('   📏 Dose: ${med.dose}\n');
          _updateResult('   ⏰ Time: ${med.time}\n');
          _updateResult('   📅 Period: ${med.startDate} to ${med.endDate}\n');
          _updateResult(
              '   🔔 Notifications: ${med.notificationIds.length} scheduled\n');
          _updateResult('   🔄 Needs Sync: ${med.needsSync ? 'Yes' : 'No'}\n');
          if (med.syncedAt != null) {
            _updateResult('   📡 Last Synced: ${med.syncedAt}\n');
          }
          _updateResult('\n');
        }
      }
    } catch (e) {
      _updateResult('❌ Error getting medications: $e\n');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateResult(String message) {
    setState(() {
      _lastTestResult += message;
    });
  }
}
