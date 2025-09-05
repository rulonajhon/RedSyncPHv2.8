// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication_schedule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicationScheduleAdapter extends TypeAdapter<MedicationSchedule> {
  @override
  final int typeId = 5;

  @override
  MedicationSchedule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MedicationSchedule(
      id: fields[0] as String,
      medicationName: fields[1] as String,
      medType: fields[2] as String,
      dose: fields[3] as String,
      frequency: fields[4] as String,
      time: fields[5] as String,
      startDate: fields[6] as String,
      endDate: fields[7] as String,
      notification: fields[8] as bool,
      notes: fields[9] as String,
      uid: fields[10] as String,
      createdAt: fields[11] as DateTime,
      syncedAt: fields[12] as DateTime?,
      needsSync: fields[13] as bool,
      isActive: fields[14] as bool,
      notificationIds: (fields[15] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, MedicationSchedule obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.medicationName)
      ..writeByte(2)
      ..write(obj.medType)
      ..writeByte(3)
      ..write(obj.dose)
      ..writeByte(4)
      ..write(obj.frequency)
      ..writeByte(5)
      ..write(obj.time)
      ..writeByte(6)
      ..write(obj.startDate)
      ..writeByte(7)
      ..write(obj.endDate)
      ..writeByte(8)
      ..write(obj.notification)
      ..writeByte(9)
      ..write(obj.notes)
      ..writeByte(10)
      ..write(obj.uid)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.syncedAt)
      ..writeByte(13)
      ..write(obj.needsSync)
      ..writeByte(14)
      ..write(obj.isActive)
      ..writeByte(15)
      ..write(obj.notificationIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationScheduleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
