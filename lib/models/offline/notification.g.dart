// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppNotificationAdapter extends TypeAdapter<AppNotification> {
  @override
  final int typeId = 4;

  @override
  AppNotification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppNotification(
      id: fields[0] as String,
      recipientId: fields[1] as String,
      type: fields[2] as String,
      title: fields[3] as String,
      message: fields[4] as String,
      data: (fields[5] as Map).cast<String, dynamic>(),
      isRead: fields[6] as bool,
      timestamp: fields[7] as DateTime,
      uid: fields[8] as String,
      createdAt: fields[9] as DateTime,
      syncedAt: fields[10] as DateTime?,
      needsSync: fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AppNotification obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.recipientId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.message)
      ..writeByte(5)
      ..write(obj.data)
      ..writeByte(6)
      ..write(obj.isRead)
      ..writeByte(7)
      ..write(obj.timestamp)
      ..writeByte(8)
      ..write(obj.uid)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.syncedAt)
      ..writeByte(11)
      ..write(obj.needsSync);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
