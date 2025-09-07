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

      try {
        await NotificationService().initNotifications();
        print('✅ Notification service initialized');
      } catch (e) {
        print('⚠️ Notification service failed to initialize: $e');
      }

      // Perform initial sync to get the latest data
      await syncMedicationSchedules();

      // Schedule today's pending notifications after sync
      await _scheduleTodaysPendingNotifications();

      print('✅ Enhanced Medication Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing Enhanced Medication Service: $e');
    }
  }

  /// Schedule notifications for today's medications that haven't been taken yet
  Future<void> _scheduleTodaysPendingNotifications() async {
    try {
      print('🔔 [DEBUG] Checking for today\'s pending notifications...');

      final user = _auth.currentUser;
      if (user == null) {
        print(
            '❌ [DEBUG] No authenticated user - skipping notification scheduling');
        return;
      }

      final todaysReminders = await getTodaysReminders(user.uid);
      print('🔔 [DEBUG] Found ${todaysReminders.length} reminders for today');
      final now = DateTime.now();

      for (final reminder in todaysReminders) {
        final reminderTime =
            (reminder['reminderDateTime'] as DateTime).toLocal();
        final medicationName = reminder['medicationName'] as String;
        final dose = reminder['dose'] as String;
        final scheduleId = reminder['id'] as String;
        print(
            '🔔 [DEBUG] Processing reminder: $medicationName, $dose, $reminderTime');

        // Only schedule if the medication time is still in the future
        if (reminderTime.isAfter(now)) {
          // Schedule only the exact time notification (no 5-minute advance reminder)
          try {
            final exactId = int.parse(
                '${scheduleId.hashCode.abs()}${reminderTime.millisecondsSinceEpoch}1'
                    .substring(0, 9));
            print(
                '🔔 [DEBUG] Scheduling exact time notification for $medicationName at $reminderTime');
            await NotificationService().scheduleMedReminder(
              id: exactId,
              title: '💊 Time for Your Medication',
              body:
                  'Hi! It\'s time to take your $medicationName ($dose). Take care! ❤️',
              scheduledDate: reminderTime,
            );
            print(
                '📱 [DEBUG] Exact time notification scheduled for $medicationName at $reminderTime');
          } catch (e) {
            print(
                '⚠️ [DEBUG] Failed to schedule exact time notification for $medicationName: $e');
          }
        } else {
          print(
              '⏭️ [DEBUG] Medication time already passed for $medicationName at $reminderTime');
        }
      }

      print('✅ [DEBUG] Today\'s pending notifications scheduling completed');
    } catch (e) {
      print('❌ [DEBUG] Error scheduling today\'s pending notifications: $e');
    }
  }

  /// Test notification system and send immediate test notification

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
        // Force refresh today's reminders after scheduling
        print(
            '🔄 Forcing refresh of today\'s reminders after creating medication');
        await getTodaysReminders(uid);
      } catch (e) {
        print('⚠️ Failed to schedule notifications: $e');
      }

      // Try to sync to Firebase if online
      try {
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult.first != ConnectivityResult.none) {
          await _syncSingleScheduleToFirebase(schedule, daysOfWeek);
          print('✅ Medication schedule synced to Firebase');
          // Force sync all schedules from Firebase to local Hive
          print(
              '🔄 Force syncing all medication schedules from Firebase to Hive after creation');
          await syncMedicationSchedules();
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
              // SIMPLE APPROACH: Only ONE notification at exact medication time
              print(
                  '� SIMPLE: Scheduling ONE notification at exact time for ${schedule.medicationName}');

              // Schedule ONLY exact time notification
              final exactId = int.parse(
                  '${schedule.id.hashCode.abs()}${date.millisecondsSinceEpoch}1'
                      .substring(0, 9));

              print(
                  '🔔 DEBUG: Scheduling exact time notification with ID: $exactId');
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
                  '📱 SIMPLE: Single notification scheduled for ${schedule.medicationName} at $scheduleDate');

              // Verify notification is scheduled
              await _verifyScheduledNotifications(
                  null, exactId, schedule.medicationName);
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

  /// Get today's medication reminders for dashboard display
  Future<List<Map<String, dynamic>>> getTodaysReminders(String uid) async {
    try {
      final schedules = await getAllMedicationSchedules();
      final now = DateTime.now();
      final todaysReminders = <Map<String, dynamic>>[];

      // Get medications already taken today
      final takenMedications = await getTakenMedicationsToday(uid);
      print('📋 Medications already taken today: $takenMedications');

      for (final schedule in schedules) {
        if (schedule.uid != uid) {
          print('⏭️ Skipping ${schedule.medicationName}: UID mismatch');
          continue;
        }
        if (!schedule.notification) {
          print(
              '⏭️ Skipping ${schedule.medicationName}: notification disabled');
          continue;
        }
        if (!schedule.isActive) {
          print('⏭️ Skipping ${schedule.medicationName}: not active');
          continue;
        }
        // Skip if medication was already taken today
        if (takenMedications.contains(schedule.id)) {
          print('⏭️ Skipping ${schedule.medicationName}: already taken today');
          continue;
        }

        // Parse time from string format "HH:MM"
        final timeParts = schedule.time.split(':');
        final reminderHour = int.tryParse(timeParts[0]) ?? 9;
        final reminderMinute = int.tryParse(timeParts[1]) ?? 0;

        final reminderTime = DateTime(
          now.year,
          now.month,
          now.day,
          reminderHour,
          reminderMinute,
        );

        // Check if medication should be taken today based on frequency
        bool shouldTakeToday = _shouldTakeMedicationToday(schedule, now);
        if (!shouldTakeToday) {
          print(
              '⏭️ Skipping ${schedule.medicationName}: shouldTakeToday=false, frequency=${schedule.frequency}, startDate=${schedule.startDate}, endDate=${schedule.endDate}');
          continue;
        }

        final reminderData = {
          'id': schedule.id,
          'medicationName': schedule.medicationName,
          'dose': schedule.dose,
          'medType': schedule.medType,
          'reminderDateTime': reminderTime,
          'isPending': reminderTime.isAfter(now),
          // Only overdue if more than 5 minutes have passed since scheduled time
          'isOverdue':
              now.isAfter(reminderTime.add(const Duration(minutes: 5))),
          'frequency': schedule.frequency,
          'notes': schedule.notes,
        };
        todaysReminders.add(reminderData);
        print(
            '✅ Added reminder for: ${schedule.medicationName} at ${schedule.time}');
      }

      // Sort by reminder time
      todaysReminders.sort((a, b) {
        final timeA = a['reminderDateTime'] as DateTime;
        final timeB = b['reminderDateTime'] as DateTime;
        return timeA.compareTo(timeB);
      });

      print(
          '📋 Found ${todaysReminders.length} reminders for today (excluding taken)');
      return todaysReminders;
    } catch (e) {
      print('❌ Error getting today\'s reminders: $e');
      return [];
    }
  }

  /// Helper method to determine if medication should be taken today
  bool _shouldTakeMedicationToday(MedicationSchedule schedule, DateTime now) {
    try {
      final startDate = DateTime.parse(schedule.startDate);
      final endDate = DateTime.parse(schedule.endDate);
      final today = DateTime(now.year, now.month, now.day);
      // Check if today is within the date range (inclusive)
      if (today.isBefore(
              DateTime(startDate.year, startDate.month, startDate.day)) ||
          today.isAfter(DateTime(endDate.year, endDate.month, endDate.day))) {
        return false;
      }
      switch (schedule.frequency.toLowerCase()) {
        case 'daily':
          return true;
        case 'once':
          // Only show if today matches startDate (or endDate)
          return today.isAtSameMomentAs(
              DateTime(startDate.year, startDate.month, startDate.day));
        case 'weekly':
          // For weekly, assume it should be taken today
          return true;
        case 'as needed':
          return true;
        default:
          return true;
      }
    } catch (e) {
      print('❌ Error checking if should take today: $e');
      return true; // Default to showing the reminder
    }
  }

  /// Mark medication as taken for today
  Future<void> markMedicationTaken(String uid, String scheduleId) async {
    try {
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Save to Firebase
      await _firestore.collection('medication_taken').add({
        'uid': uid,
        'scheduleId': scheduleId,
        'date': dateKey,
        'takenAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Also save to local storage for offline access
      await _offlineService.initialize();
      final box = await Hive.openBox('medication_taken');
      final localKey = '${uid}_${scheduleId}_$dateKey';
      await box.put(localKey, {
        'uid': uid,
        'scheduleId': scheduleId,
        'date': dateKey,
        'takenAt': DateTime.now().toIso8601String(),
      });

      print('✅ Medication marked as taken: $scheduleId on $dateKey');
    } catch (e) {
      print('❌ Error marking medication as taken: $e');
      rethrow;
    }
  }

  /// Get medications taken today (from both online and offline storage)
  Future<Set<String>> getTakenMedicationsToday(String uid) async {
    try {
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final takenMedications = <String>{};

      // Try to get from Firebase first
      try {
        final snapshot = await _firestore
            .collection('medication_taken')
            .where('uid', isEqualTo: uid)
            .where('date', isEqualTo: dateKey)
            .get();

        takenMedications.addAll(
          snapshot.docs.map((doc) => doc.data()['scheduleId'] as String),
        );
      } catch (e) {
        print('⚠️ Failed to get taken medications from Firebase: $e');
      }

      // Also check local storage for offline data
      try {
        await _offlineService.initialize();
        final box = await Hive.openBox('medication_taken');
        for (final key in box.keys) {
          if (key.toString().startsWith('${uid}_') &&
              key.toString().endsWith('_$dateKey')) {
            final data = box.get(key);
            if (data != null && data['scheduleId'] != null) {
              takenMedications.add(data['scheduleId'] as String);
            }
          }
        }
      } catch (e) {
        print('⚠️ Failed to get taken medications from local storage: $e');
      }

      print('📋 Found ${takenMedications.length} taken medications for today');
      return takenMedications;
    } catch (e) {
      print('❌ Error getting taken medications: $e');
      return <String>{};
    }
  }

  /// Clear today's taken medication status (for debugging/testing)
  Future<void> clearTodaysTakenStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user for clearing taken status');
        return;
      }

      final uid = user.uid;
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      print('🗑️ Clearing taken medications for today ($dateKey)...');

      // Clear from Firebase
      try {
        final snapshot = await _firestore
            .collection('medication_taken')
            .where('uid', isEqualTo: uid)
            .where('date', isEqualTo: dateKey)
            .get();

        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        print('✅ Cleared ${snapshot.docs.length} taken records from Firebase');
      } catch (e) {
        print('⚠️ Failed to clear taken medications from Firebase: $e');
      }

      // Clear from local storage
      try {
        await _offlineService.initialize();
        final box = await Hive.openBox('medication_taken');
        final keysToDelete = <dynamic>[];

        for (final key in box.keys) {
          if (key.toString().startsWith('${uid}_') &&
              key.toString().endsWith('_$dateKey')) {
            keysToDelete.add(key);
          }
        }

        for (final key in keysToDelete) {
          await box.delete(key);
        }
        print(
            '✅ Cleared ${keysToDelete.length} taken records from local storage');
      } catch (e) {
        print('⚠️ Failed to clear taken medications from local storage: $e');
      }

      // Re-schedule today's notifications since medications are no longer marked as taken
      await _scheduleTodaysPendingNotifications();

      print('✅ Today\'s taken status cleared successfully');
    } catch (e) {
      print('❌ Error clearing today\'s taken status: $e');
      rethrow;
    }
  }

  /// Verify that notifications were actually scheduled in the system
  Future<void> _verifyScheduledNotifications(
      int? reminderId, int exactId, String medicationName) async {
    // Pending notification verification removed (API no longer available)
    // This function is now a placeholder.
  }
}
