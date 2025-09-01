// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_bleed.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BleedLogAdapter extends TypeAdapter<BleedLog> {
  @override
  final int typeId = 2;

  @override
  BleedLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BleedLog(
      id: fields[0] as String,
      date: fields[1] as String,
      time: fields[2] as String,
      bodyRegion: fields[3] as String,
      severity: fields[4] as String,
      specificRegion: fields[5] as String,
      notes: fields[6] as String,
      uid: fields[7] as String,
      createdAt: fields[8] as DateTime,
      syncedAt: fields[9] as DateTime?,
      needsSync: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, BleedLog obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.time)
      ..writeByte(3)
      ..write(obj.bodyRegion)
      ..writeByte(4)
      ..write(obj.severity)
      ..writeByte(5)
      ..write(obj.specificRegion)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.uid)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.syncedAt)
      ..writeByte(10)
      ..write(obj.needsSync);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BleedLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
