import 'package:hive/hive.dart';

part 'medication_schedule.g.dart';

@HiveType(typeId: 5)
class MedicationSchedule extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String medicationName;

  @HiveField(2)
  String medType;

  @HiveField(3)
  String dose;

  @HiveField(4)
  String frequency;

  @HiveField(5)
  String time;

  @HiveField(6)
  String startDate;

  @HiveField(7)
  String endDate;

  @HiveField(8)
  bool notification;

  @HiveField(9)
  String notes;

  @HiveField(10)
  String uid;

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  DateTime? syncedAt;

  @HiveField(13)
  bool needsSync;

  @HiveField(14)
  bool isActive;

  @HiveField(15)
  List<String> notificationIds;

  MedicationSchedule({
    required this.id,
    required this.medicationName,
    required this.medType,
    required this.dose,
    required this.frequency,
    required this.time,
    required this.startDate,
    required this.endDate,
    required this.notification,
    required this.notes,
    required this.uid,
    required this.createdAt,
    this.syncedAt,
    this.needsSync = true,
    this.isActive = true,
    this.notificationIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'medicationName': medicationName,
      'medType': medType,
      'dose': dose,
      'frequency': frequency,
      'time': time,
      'startDate': startDate,
      'endDate': endDate,
      'notification': notification,
      'notes': notes,
      'uid': uid,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'notificationIds': notificationIds,
    };
  }

  static MedicationSchedule fromMap(
      Map<String, dynamic> map, String documentId) {
    return MedicationSchedule(
      id: documentId,
      medicationName: map['medicationName'] ?? '',
      medType: map['medType'] ?? '',
      dose: map['dose'] ?? '',
      frequency: map['frequency'] ?? '',
      time: map['time'] ?? '',
      startDate: map['startDate'] ?? '',
      endDate: map['endDate'] ?? '',
      notification: map['notification'] ?? true,
      notes: map['notes'] ?? '',
      uid: map['uid'] ?? '',
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt']
          : DateTime.parse(
              map['createdAt'] ?? DateTime.now().toIso8601String()),
      isActive: map['isActive'] ?? true,
      notificationIds: List<String>.from(map['notificationIds'] ?? []),
      needsSync: false,
      syncedAt: DateTime.now(),
    );
  }
}
