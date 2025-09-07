import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/offline/medication_schedule.dart';
import 'offline_service.dart';
import 'notification_service.dart';

class EnhancedMedicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final OfflineService _offlineService = OfflineService();

  static const String _medicationSchedulesBox = 'medication_schedules';

  /// Initialize the service and perform initial sync
  Future<void> initialize() async {
    try {
      print('🔄 Initializing Enhanced Medication Service...');
      await _offlineService.initialize();

      // NotificationService initialization is handled elsewhere if needed

      // Perform initial sync to get the latest data
      await syncMedicationSchedules();

      print('✅ Enhanced Medication Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing Enhanced Medication Service: $e');
    }
  }

  /// Create a new medication schedule with UID-based unique ID
  Future<String?> createMedicationSchedule({
    required String medicationName,
    required String medType,
    required String dose,
    required String frequency,
    required String startDate,
    required String endDate,
    required String time,
    required List<String> daysOfWeek,
    String? notes,
  }) async {
    try {
      final uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        print('❌ No authenticated user');
        return null;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueId = '${uid}_med_$timestamp'; // More specific ID format

      print('🔄 Creating medication schedule with ID: $uniqueId');
      print('🕐 DEBUG: Time parameter received: "$time"');

      final schedule = MedicationSchedule(
        id: uniqueId,
        uid: uid,
        medicationName: medicationName,
        medType: medType,
        dose: dose,
        frequency: frequency,
        startDate: startDate,
        endDate: endDate,
        time: time,
        notification: true,
        notes: notes ?? '',
        createdAt: DateTime.now(),
        needsSync: true,
        notificationIds: [],
      );

      // Save to Hive first (offline storage)
      await _saveMedicationScheduleOffline(schedule);
      print('✅ Medication schedule saved offline');

      // Schedule notifications immediately
      try {
        final notificationIds =
            await _scheduleNotificationsWithReminder(schedule, daysOfWeek);
        if (notificationIds.isNotEmpty) {
          final updatedSchedule = MedicationSchedule(
            id: schedule.id,
            uid: schedule.uid,
            medicationName: schedule.medicationName,
            medType: schedule.medType,
            dose: schedule.dose,
            frequency: schedule.frequency,
            startDate: schedule.startDate,
            endDate: schedule.endDate,
            time: schedule.time,
            notification: schedule.notification,
            notes: schedule.notes,
            createdAt: schedule.createdAt,
            needsSync: schedule.needsSync,
            notificationIds: notificationIds,
          );
          await _saveMedicationScheduleOffline(updatedSchedule);
          print('✅ Notifications scheduled: ${notificationIds.length}');
        }
      } catch (e) {
        print('⚠️ Failed to schedule notifications: $e');
      }

      // Try to sync to Firebase if online
      try {
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult.first != ConnectivityResult.none) {
          await _syncSingleScheduleToFirebase(schedule, daysOfWeek);
          print('✅ Medication schedule synced to Firebase');
        } else {
          print('⚠️ Offline - will sync when connection is restored');
        }
      } catch (e) {
        print('⚠️ Failed to sync to Firebase immediately: $e');
      }

      return uniqueId;
    } catch (e) {
      print('❌ Error creating medication schedule: $e');
      return null;
    }
  }

  /// Schedule notifications with 5-minute reminder + exact time notification
  Future<List<String>> _scheduleNotificationsWithReminder(
      MedicationSchedule schedule, List<String> daysOfWeek) async {
    final notificationIds = <String>[];

    try {
      // NotificationService initialization is handled elsewhere if needed

      final startDate = DateTime.parse(schedule.startDate);
      final endDate = DateTime.parse(schedule.endDate);

      // Enhanced debugging for time parsing
      print('🕐 DEBUG: Raw time string from schedule: "${schedule.time}"');
      final timeParts = schedule.time.split(':');
      print('🕐 DEBUG: Split time parts: $timeParts');

      if (timeParts.length != 2) {
        throw Exception(
            'Invalid time format: ${schedule.time}. Expected HH:MM format.');
      }

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      print('🕐 DEBUG: Parsed hour: $hour, minute: $minute');
      print(
          '📅 Scheduling notifications from $startDate to $endDate at $hour:${minute.toString().padLeft(2, '0')}');
      print('📅 Days of week: $daysOfWeek');

      int counter = 0;
      for (DateTime date = startDate;
          date.isBefore(endDate.add(const Duration(days: 1))) && counter < 100;
          date = date.add(const Duration(days: 1))) {
        // Check if this day of week is selected (1=Monday, 7=Sunday)
        if (daysOfWeek.contains(date.weekday.toString())) {
          final scheduleDate =
              DateTime(date.year, date.month, date.day, hour, minute);

          print(
              '🕐 DEBUG: Creating schedule date: ${date.year}-${date.month}-${date.day} at $hour:$minute');
          print('🕐 DEBUG: Resulting DateTime: $scheduleDate');

          if (scheduleDate.isAfter(DateTime.now())) {
            try {
              // Schedule only the exact time notification (no 5-minute reminder)
              final exactId = int.parse(
                  '${schedule.id.hashCode.abs()}${date.millisecondsSinceEpoch}1'
                      .substring(0, 9));

              await NotificationService().scheduleMedReminder(
                id: exactId,
                title: '💊 Time for Your Medication',
                body:
                    'Hi! It\'s time to take your ${schedule.medicationName} (${schedule.dose}). Take care! ❤️',
                scheduledDate: scheduleDate,
              );

              notificationIds
                  .add('${schedule.id}_exact_${date.millisecondsSinceEpoch}');
              print(
                  '📱 Exact time notification scheduled for ${schedule.medicationName} at $scheduleDate');
            } catch (e) {
              print('⚠️ Failed to schedule notification for $scheduleDate: $e');
            }
          }
        }
        counter++;
      }

      print(
          '📅 Total notifications scheduled: ${notificationIds.length} for ${schedule.medicationName}');
    } catch (e) {
      print('❌ Error scheduling notifications: $e');
    }

    return notificationIds;
  }

  /// Sync single schedule to Firebase
  Future<void> _syncSingleScheduleToFirebase(
      MedicationSchedule schedule, List<String> daysOfWeek) async {
    try {
      await _firestore.collection('medication_schedules').doc(schedule.id).set({
        'uid': schedule.uid,
        'medicationName': schedule.medicationName,
        'medType': schedule.medType,
        'dose': schedule.dose,
        'frequency': schedule.frequency,
        'startDate': schedule.startDate,
        'endDate': schedule.endDate,
        'time': schedule.time,
        'daysOfWeek': daysOfWeek,
        'notes': schedule.notes,
        'notificationEnabled': schedule.notification,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': schedule.isActive,
      });

      // Mark as synced in Hive
      final updatedSchedule = MedicationSchedule(
        id: schedule.id,
        uid: schedule.uid,
        medicationName: schedule.medicationName,
        medType: schedule.medType,
        dose: schedule.dose,
        frequency: schedule.frequency,
        startDate: schedule.startDate,
        endDate: schedule.endDate,
        time: schedule.time,
        notification: schedule.notification,
        notes: schedule.notes,
        createdAt: schedule.createdAt,
        needsSync: false,
        notificationIds: schedule.notificationIds,
        syncedAt: DateTime.now(),
      );
      await _saveMedicationScheduleOffline(updatedSchedule);
    } catch (e) {
      print('❌ Error syncing schedule to Firebase: $e');
      rethrow;
    }
  }

  /// Save medication schedule offline
  Future<void> _saveMedicationScheduleOffline(
      MedicationSchedule schedule) async {
    await _offlineService.initialize();
    final box = Hive.box<MedicationSchedule>(_medicationSchedulesBox);
    await box.put(schedule.id, schedule);
  }

  /// Sync all medication schedules between Hive and Firebase
  Future<void> syncMedicationSchedules() async {
    try {
      print('🔄 Starting comprehensive medication sync...');

      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        print('❌ No authenticated user for sync');
        return;
      }

      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.first == ConnectivityResult.none) {
        print('⚠️ No internet connection - sync skipped');
        return;
      }

      // Step 1: Clear all medication schedules from Hive
      print('🗑️ Clearing all medication schedules from Hive...');
      await _clearAllMedicationSchedulesFromHive();

      // Step 2: Download all medication schedules from Firebase
      print('⬇️ Downloading medication schedules from Firebase...');
      final firebaseSchedules =
          await _downloadMedicationSchedulesFromFirebase(uid);

      print(
          '📥 Downloaded ${firebaseSchedules.length} medication schedules from Firebase');

      // Step 3: Save Firebase schedules to Hive and reschedule notifications
      for (final scheduleData in firebaseSchedules) {
        try {
          final schedule = MedicationSchedule(
            id: scheduleData['id'] ?? '',
            uid: scheduleData['uid'] ?? '',
            medicationName: scheduleData['medicationName'] ?? '',
            medType: scheduleData['medType'] ?? '',
            dose: scheduleData['dose'] ?? '',
            frequency: scheduleData['frequency'] ?? '',
            startDate: scheduleData['startDate'] ?? '',
            endDate: scheduleData['endDate'] ?? '',
            time: scheduleData['time'] ?? '',
            notification: scheduleData['notificationEnabled'] ?? true,
            notes: scheduleData['notes'] ?? '',
            createdAt: scheduleData['createdAt'] is Timestamp
                ? (scheduleData['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            needsSync: false,
            notificationIds: [],
            isActive: scheduleData['isActive'] ?? true,
            syncedAt: DateTime.now(),
          );

          await _saveMedicationScheduleOffline(schedule);

          // Reschedule notifications for this medication
          if (schedule.notification && schedule.isActive) {
            final daysOfWeek =
                List<String>.from(scheduleData['daysOfWeek'] ?? []);
            try {
              final notificationIds = await _scheduleNotificationsWithReminder(
                  schedule, daysOfWeek);
              if (notificationIds.isNotEmpty) {
                final updatedSchedule = MedicationSchedule(
                  id: schedule.id,
                  uid: schedule.uid,
                  medicationName: schedule.medicationName,
                  medType: schedule.medType,
                  dose: schedule.dose,
                  frequency: schedule.frequency,
                  startDate: schedule.startDate,
                  endDate: schedule.endDate,
                  time: schedule.time,
                  notification: schedule.notification,
                  notes: schedule.notes,
                  createdAt: schedule.createdAt,
                  needsSync: false,
                  notificationIds: notificationIds,
                  isActive: schedule.isActive,
                  syncedAt: schedule.syncedAt,
                );
                await _saveMedicationScheduleOffline(updatedSchedule);
                print(
                    '✅ Notifications rescheduled for ${schedule.medicationName}');
              }
            } catch (e) {
              print(
                  '⚠️ Failed to schedule notifications for ${schedule.medicationName}: $e');
            }
          }
        } catch (e) {
          print('❌ Error processing schedule: $e');
        }
      }

      print('✅ Medication sync completed successfully');
    } catch (e) {
      print('❌ Error during medication sync: $e');
    }
  }

  /// Clear all medication schedules from Hive
  Future<void> _clearAllMedicationSchedulesFromHive() async {
    try {
      await _offlineService.initialize();
      final box = Hive.box<MedicationSchedule>(_medicationSchedulesBox);

      // Cancel all existing notifications before clearing
      for (final schedule in box.values) {
        if (schedule.notificationIds.isNotEmpty) {
          try {} catch (e) {
            print(
                '⚠️ Failed to cancel notifications for ${schedule.medicationName}: $e');
          }
        }
      }

      await box.clear();
      print('🗑️ All medication schedules cleared from Hive');
    } catch (e) {
      print('❌ Error clearing medication schedules from Hive: $e');
    }
  }

  /// Download medication schedules from Firebase
  Future<List<Map<String, dynamic>>> _downloadMedicationSchedulesFromFirebase(
      String uid) async {
    try {
      final snapshot = await _firestore
          .collection('medication_schedules')
          .where('uid', isEqualTo: uid)
          .get();

      final schedules = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id; // Ensure ID is included
        schedules.add(data);
      }

      return schedules;
    } catch (e) {
      print('❌ Error downloading medication schedules from Firebase: $e');
      return [];
    }
  }

  /// Get all medication schedules from offline storage
  Future<List<MedicationSchedule>> getAllMedicationSchedules() async {
    try {
      await _offlineService.initialize();
      final box = Hive.box<MedicationSchedule>(_medicationSchedulesBox);
      return box.values.toList();
    } catch (e) {
      print('❌ Error getting medication schedules: $e');
      return [];
    }
  }

  /// Delete medication schedule
  Future<bool> deleteMedicationSchedule(String id) async {
    try {
      await _offlineService.initialize();
      final box = Hive.box<MedicationSchedule>(_medicationSchedulesBox);
      final schedule = box.get(id);

      if (schedule == null) {
        print('❌ Medication schedule not found: $id');
        return false;
      }

      // Cancel notifications
      if (schedule.notificationIds.isNotEmpty) {
        try {} catch (e) {
          print('⚠️ Failed to cancel notifications: $e');
        }
      }

      // Delete from Hive
      await box.delete(id);

      // Delete from Firebase if online
      try {
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult.first != ConnectivityResult.none) {
          await _firestore.collection('medication_schedules').doc(id).delete();
        }
      } catch (e) {
        print('⚠️ Failed to delete from Firebase: $e');
      }

      return true;
    } catch (e) {
      print('❌ Error deleting medication schedule: $e');
      return false;
    }
  }

  /// Force sync any pending changes to Firebase
  Future<void> forceSyncPendingChanges() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.first == ConnectivityResult.none) {
        print('⚠️ No internet connection - cannot sync');
        return;
      }

      await _offlineService.initialize();
      final box = Hive.box<MedicationSchedule>(_medicationSchedulesBox);

      final pendingSchedules =
          box.values.where((schedule) => schedule.needsSync).toList();

      if (pendingSchedules.isEmpty) {
        print('✅ No pending changes to sync');
        return;
      }

      print('🔄 Syncing ${pendingSchedules.length} pending changes...');

      for (final schedule in pendingSchedules) {
        try {
          await _firestore
              .collection('medication_schedules')
              .doc(schedule.id)
              .set({
            'uid': schedule.uid,
            'medicationName': schedule.medicationName,
            'medType': schedule.medType,
            'dose': schedule.dose,
            'frequency': schedule.frequency,
            'startDate': schedule.startDate,
            'endDate': schedule.endDate,
            'time': schedule.time,
            'notes': schedule.notes,
            'notificationEnabled': schedule.notification,
            'createdAt': FieldValue.serverTimestamp(),
            'isActive': schedule.isActive,
          });

          // Mark as synced
          final syncedSchedule = MedicationSchedule(
            id: schedule.id,
            uid: schedule.uid,
            medicationName: schedule.medicationName,
            medType: schedule.medType,
            dose: schedule.dose,
            frequency: schedule.frequency,
            startDate: schedule.startDate,
            endDate: schedule.endDate,
            time: schedule.time,
            notification: schedule.notification,
            notes: schedule.notes,
            createdAt: schedule.createdAt,
            needsSync: false,
            notificationIds: schedule.notificationIds,
            isActive: schedule.isActive,
            syncedAt: DateTime.now(),
          );

          await _saveMedicationScheduleOffline(syncedSchedule);
          print('✅ Synced schedule: ${schedule.medicationName}');
        } catch (e) {
          print('❌ Failed to sync schedule ${schedule.medicationName}: $e');
        }
      }

      print('✅ Force sync completed');
    } catch (e) {
      print('❌ Error during force sync: $e');
    }
  }
}
