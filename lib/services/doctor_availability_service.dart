import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DoctorAvailabilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save doctor's availability settings
  Future<void> saveAvailabilitySettings({
    required String doctorUid,
    required bool isAvailable,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required List<String> availableDays,
  }) async {
    try {
      await _firestore.collection('doctor_availability').doc(doctorUid).set({
        'isAvailable': isAvailable,
        'startTime': {
          'hour': startTime.hour,
          'minute': startTime.minute,
        },
        'endTime': {
          'hour': endTime.hour,
          'minute': endTime.minute,
        },
        'availableDays': availableDays,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving availability settings: $e');
      rethrow;
    }
  }

  // Get doctor's availability settings
  Future<Map<String, dynamic>?> getAvailabilitySettings(
      String doctorUid) async {
    try {
      final doc = await _firestore
          .collection('doctor_availability')
          .doc(doctorUid)
          .get();

      if (doc.exists) {
        return doc.data();
      }

      // Return default settings if none exist
      return {
        'isAvailable': true,
        'startTime': {'hour': 8, 'minute': 0},
        'endTime': {'hour': 18, 'minute': 0},
        'availableDays': [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday'
        ],
        'lastUpdated': null,
      };
    } catch (e) {
      print('Error getting availability settings: $e');
      return null;
    }
  }

  // Check if doctor is currently available for messages
  Future<Map<String, dynamic>> checkDoctorAvailability(String doctorUid) async {
    try {
      final settings = await getAvailabilitySettings(doctorUid);

      if (settings == null) {
        return {
          'isAvailable': false,
          'reason': 'Unable to check availability',
          'message': 'Please try again later',
        };
      }

      // Check if doctor has disabled messages entirely
      if (!settings['isAvailable']) {
        return {
          'isAvailable': false,
          'reason': 'messages_disabled',
          'message': 'This doctor is currently not accepting messages',
        };
      }

      final now = DateTime.now();
      final currentDay = _getCurrentDayName(now);

      // Check if today is an available day
      final availableDays = List<String>.from(settings['availableDays'] ?? []);
      if (!availableDays.contains(currentDay)) {
        return {
          'isAvailable': false,
          'reason': 'day_unavailable',
          'message': 'This doctor is not available on $currentDay',
          'availableDays': availableDays,
        };
      }

      // Check if current time is within available hours
      final currentTime = TimeOfDay.now();
      final startTime = TimeOfDay(
        hour: settings['startTime']['hour'],
        minute: settings['startTime']['minute'],
      );
      final endTime = TimeOfDay(
        hour: settings['endTime']['hour'],
        minute: settings['endTime']['minute'],
      );

      final currentMinutes = currentTime.hour * 60 + currentTime.minute;
      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;

      if (currentMinutes < startMinutes || currentMinutes > endMinutes) {
        return {
          'isAvailable': false,
          'reason': 'time_unavailable',
          'message':
              'This doctor is available from ${_formatTime(startTime)} to ${_formatTime(endTime)}',
          'availableHours': {
            'start': _formatTime(startTime),
            'end': _formatTime(endTime),
          },
        };
      }

      // Doctor is currently available
      return {
        'isAvailable': true,
        'reason': 'available',
        'message': 'Doctor is currently available for messages',
      };
    } catch (e) {
      print('Error checking doctor availability: $e');
      return {
        'isAvailable': false,
        'reason': 'error',
        'message': 'Unable to check availability. Please try again later.',
      };
    }
  }

  // Get availability status for multiple doctors (for patient's doctor list)
  Future<Map<String, Map<String, dynamic>>> checkMultipleDoctorAvailability(
      List<String> doctorUids) async {
    final Map<String, Map<String, dynamic>> results = {};

    for (String doctorUid in doctorUids) {
      results[doctorUid] = await checkDoctorAvailability(doctorUid);
    }

    return results;
  }

  // Stream doctor availability in real-time
  Stream<Map<String, dynamic>> streamDoctorAvailability(String doctorUid) {
    return _firestore
        .collection('doctor_availability')
        .doc(doctorUid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return {
          'isAvailable': true,
          'startTime': {'hour': 8, 'minute': 0},
          'endTime': {'hour': 18, 'minute': 0},
          'availableDays': [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday'
          ],
        };
      }
      return doc.data() ?? {};
    });
  }

  // Helper methods
  String _getCurrentDayName(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return weekdays[date.weekday - 1];
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour == 0 ? 12 : hour}:$minute $period';
  }
}
