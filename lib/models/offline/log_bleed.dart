import 'package:hive/hive.dart';

part 'log_bleed.g.dart';

@HiveType(typeId: 2)
class BleedLog extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String date;

  @HiveField(2)
  String time;

  @HiveField(3)
  String bodyRegion;

  @HiveField(4)
  String severity;

  @HiveField(5)
  String specificRegion;

  @HiveField(6)
  String notes;

  @HiveField(7)
  String uid;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime? syncedAt;

  @HiveField(10)
  bool needsSync;

  BleedLog({
    required this.id,
    required this.date,
    required this.time,
    required this.bodyRegion,
    required this.severity,
    required this.specificRegion,
    required this.notes,
    required this.uid,
    required this.createdAt,
    this.syncedAt,
    this.needsSync = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'time': time,
      'bodyRegion': bodyRegion,
      'severity': severity,
      'specificRegion': specificRegion,
      'notes': notes,
      'uid': uid,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
