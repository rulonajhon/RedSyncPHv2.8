import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/offline_service.dart';

/// Example implementation showing how to integrate offline functionality
/// with bleed logging. This demonstrates the pattern that can be applied
/// to existing screens.
class LogBleedOfflineExample extends StatefulWidget {
  const LogBleedOfflineExample({super.key});

  @override
  State<LogBleedOfflineExample> createState() => _LogBleedOfflineExampleState();
}

class _LogBleedOfflineExampleState extends State<LogBleedOfflineExample> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _severityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final OfflineService _offlineService = OfflineService();

  bool _isSaving = false;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _initOfflineService();
    _checkConnectivity();
  }

  Future<void> _initOfflineService() async {
    try {
      await _offlineService.initialize();
      print('Offline service initialized successfully');
    } catch (e) {
      print('Error initializing offline service: $e');
    }
  }

  Future<void> _checkConnectivity() async {
    final isOnline = await _offlineService.isOnline();
    setState(() {
      _isOnline = isOnline;
    });
  }

  Future<void> _saveBleedLog() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Save using offline service - it handles both local storage and cloud sync
      await _offlineService.saveBleedLogOffline(
        bodyRegion: _locationController.text.trim(),
        specificRegion: _locationController.text.trim(),
        severity: _severityController.text.trim(),
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        time: TimeOfDay.now().format(context),
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;

      // Show success message with online/offline indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text(_isOnline
                  ? 'Bleed logged successfully and synced!'
                  : 'Bleed logged offline - will sync when online'),
            ],
          ),
          backgroundColor: _isOnline ? Colors.green : Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Clear form
      _locationController.clear();
      _severityController.clear();
      _notesController.clear();
    } catch (e) {
      print('Error saving bleed log: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Error saving bleed log. Please try again.'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _loadBleedLogs() async {
    try {
      final logs = await _offlineService.getBleedLogs();

      if (!mounted) return;

      // Show dialog with recent logs
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Recent Bleed Logs (${logs.length})'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Card(
                  child: ListTile(
                    title: Text('${log.bodyRegion} - ${log.severity}'),
                    subtitle: Text('${log.date} ${log.time}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          log.needsSync
                              ? Icons.sync_problem
                              : Icons.check_circle,
                          color: log.needsSync ? Colors.orange : Colors.green,
                          size: 16,
                        ),
                        Text(log.needsSync ? 'Pending' : 'Synced'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error loading bleed logs: $e');
    }
  }

  Future<void> _syncPendingData() async {
    try {
      setState(() => _isSaving = true);

      await _offlineService.syncAllData();
      await _checkConnectivity();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.sync, color: Colors.white),
              SizedBox(width: 8),
              Text('Data synced successfully!'),
            ],
          ),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Error syncing data: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.sync_problem, color: Colors.white),
              SizedBox(width: 8),
              Text('Sync failed: ${e.toString()}'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Bleed (Offline Example)'),
        actions: [
          // Online/Offline indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _isOnline ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isOnline ? Icons.cloud_done : Icons.cloud_off,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          // Sync button
          IconButton(
            onPressed: _isOnline ? _syncPendingData : null,
            icon: const Icon(Icons.sync),
            tooltip: 'Sync pending data',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Offline capabilities info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Offline Capabilities',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Your data is automatically saved locally\n'
                      '• Syncs with cloud when connection is available\n'
                      '• All critical features work offline',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Form fields
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Bleed Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter bleed location';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _severityController,
                decoration: const InputDecoration(
                  labelText: 'Severity',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter severity';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveBleedLog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Save Bleed Log'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _loadBleedLogs,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 24),
                    ),
                    child: const Text('View Logs'),
                  ),
                ],
              ),

              const Spacer(),

              // Offline status info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Integration Notes:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Replace existing database calls with OfflineService methods\n'
                      '• Add connectivity status indicators\n'
                      '• Handle sync status in UI\n'
                      '• Show appropriate offline messages',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    _severityController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
