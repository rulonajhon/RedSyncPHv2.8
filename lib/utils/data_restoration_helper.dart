import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DataRestorationHelper {
  static Future<void> addSampleData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return;
      }

      final firestore = FirebaseFirestore.instance;
      final userId = user.uid;
      print('🔄 Adding sample data for user: $userId');

      // Add sample bleed logs
      await _addSampleBleedLogs(firestore, userId);

      // Add sample infusion logs
      await _addSampleInfusionLogs(firestore, userId);

      // Add sample medication schedules
      await _addSampleMedicationSchedules(firestore, userId);

      print('✅ Sample data added successfully!');
    } catch (e) {
      print('❌ Error adding sample data: $e');
    }
  }

  static Future<void> _addSampleBleedLogs(
      FirebaseFirestore firestore, String userId) async {
    final today = DateTime.now();

    final bleedLogs = [
      {
        'id': 'bleed_${DateTime.now().millisecondsSinceEpoch}_1',
        'userId': userId,
        'location': 'Knee',
        'severity': 'Mild',
        'duration': '2 hours',
        'treatment': 'Ice pack applied',
        'notes': 'Minor bleeding after exercise',
        'createdAt': today.subtract(const Duration(days: 1)).toIso8601String(),
        'date': today
            .subtract(const Duration(days: 1))
            .toIso8601String()
            .split('T')[0],
      },
      {
        'id': 'bleed_${DateTime.now().millisecondsSinceEpoch}_2',
        'userId': userId,
        'location': 'Elbow',
        'severity': 'Moderate',
        'duration': '4 hours',
        'treatment': 'Factor VIII administered',
        'notes': 'Spontaneous bleeding',
        'createdAt': today.subtract(const Duration(days: 3)).toIso8601String(),
        'date': today
            .subtract(const Duration(days: 3))
            .toIso8601String()
            .split('T')[0],
      },
      {
        'id': 'bleed_${DateTime.now().millisecondsSinceEpoch}_3',
        'userId': userId,
        'location': 'Ankle',
        'severity': 'Mild',
        'duration': '1 hour',
        'treatment': 'Rest and elevation',
        'notes': 'Minor joint bleed',
        'createdAt': today.subtract(const Duration(days: 5)).toIso8601String(),
        'date': today
            .subtract(const Duration(days: 5))
            .toIso8601String()
            .split('T')[0],
      },
    ];

    for (final bleedLog in bleedLogs) {
      await firestore
          .collection('bleed_logs')
          .doc(bleedLog['id'] as String)
          .set(bleedLog);
    }

    print('✅ Added ${bleedLogs.length} sample bleed logs');
  }

  static Future<void> _addSampleInfusionLogs(
      FirebaseFirestore firestore, String userId) async {
    final today = DateTime.now();

    final infusionLogs = [
      {
        'id': 'infusion_${DateTime.now().millisecondsSinceEpoch}_1',
        'userId': userId,
        'medicationName': 'Factor VIII',
        'dosage': '2000 IU',
        'infusionTime':
            today.subtract(const Duration(days: 1)).toIso8601String(),
        'location': 'Left arm',
        'notes': 'Prophylactic dose',
        'createdAt': today.subtract(const Duration(days: 1)).toIso8601String(),
        'date': today
            .subtract(const Duration(days: 1))
            .toIso8601String()
            .split('T')[0],
      },
      {
        'id': 'infusion_${DateTime.now().millisecondsSinceEpoch}_2',
        'userId': userId,
        'medicationName': 'Factor IX',
        'dosage': '1500 IU',
        'infusionTime':
            today.subtract(const Duration(days: 4)).toIso8601String(),
        'location': 'Right arm',
        'notes': 'Treatment for elbow bleed',
        'createdAt': today.subtract(const Duration(days: 4)).toIso8601String(),
        'date': today
            .subtract(const Duration(days: 4))
            .toIso8601String()
            .split('T')[0],
      },
    ];

    for (final infusionLog in infusionLogs) {
      await firestore
          .collection('infusion_logs')
          .doc(infusionLog['id'] as String)
          .set(infusionLog);
    }

    print('✅ Added ${infusionLogs.length} sample infusion logs');
  }

  static Future<void> _addSampleMedicationSchedules(
      FirebaseFirestore firestore, String userId) async {
    final medicationSchedules = [
      {
        'id': '${userId}_med_${DateTime.now().millisecondsSinceEpoch}_1',
        'userId': userId,
        'medicationName': 'Factor VIII',
        'dose': '2000 IU',
        'frequency': 'Every 2 days',
        'time': '09:00',
        'daysOfWeek': ['1', '3', '5'], // Monday, Wednesday, Friday
        'startDate': DateTime.now().toIso8601String(),
        'endDate':
            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        'notes': 'Prophylactic treatment',
      },
      {
        'id': '${userId}_med_${DateTime.now().millisecondsSinceEpoch}_2',
        'userId': userId,
        'medicationName': 'Vitamin D',
        'dose': '1000 IU',
        'frequency': 'Daily',
        'time': '20:00',
        'daysOfWeek': ['1', '2', '3', '4', '5', '6', '7'], // Every day
        'startDate': DateTime.now().toIso8601String(),
        'endDate':
            DateTime.now().add(const Duration(days: 90)).toIso8601String(),
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        'notes': 'Daily supplement',
      },
    ];

    for (final schedule in medicationSchedules) {
      await firestore
          .collection('medication_schedules')
          .doc(schedule['id'] as String)
          .set(schedule);
    }

    print('✅ Added ${medicationSchedules.length} sample medication schedules');
  }
}
