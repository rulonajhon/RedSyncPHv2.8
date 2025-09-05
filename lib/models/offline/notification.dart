import 'package:hive/hive.dart';

part 'notification.g.dart';

@HiveType(typeId: 4)
class AppNotification extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String recipientId;

  @HiveField(2)
  String type;

  @HiveField(3)
  String title;

  @HiveField(4)
  String message;

  @HiveField(5)
  Map<String, dynamic> data;

  @HiveField(6)
  bool isRead;

  @HiveField(7)
  DateTime timestamp;

  @HiveField(8)
  String uid;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime? syncedAt;

  @HiveField(11)
  bool needsSync;

  AppNotification({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    required this.isRead,
    required this.timestamp,
    required this.uid,
    required this.createdAt,
    this.syncedAt,
    this.needsSync = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'isRead': isRead,
      'timestamp': timestamp.toIso8601String(),
      'uid': uid,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static AppNotification fromMap(Map<String, dynamic> map, String documentId) {
    return AppNotification(
      id: documentId,
      recipientId: map['recipientId'] ?? '',
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      isRead: map['isRead'] ?? false,
      timestamp: map['timestamp'] is DateTime
          ? map['timestamp']
          : DateTime.parse(
              map['timestamp'] ?? DateTime.now().toIso8601String()),
      uid: map['uid'] ?? '',
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt']
          : DateTime.parse(
              map['createdAt'] ?? DateTime.now().toIso8601String()),
      needsSync: false,
      syncedAt: DateTime.now(),
    );
  }
}
