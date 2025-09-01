// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calculator_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CalculatorHistoryAdapter extends TypeAdapter<CalculatorHistory> {
  @override
  final int typeId = 3;

  @override
  CalculatorHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CalculatorHistory(
      id: fields[0] as String,
      weight: fields[1] as double,
      factorType: fields[2] as String,
      targetLevel: fields[3] as double,
      calculatedDose: fields[4] as double,
      notes: fields[5] as String,
      createdAt: fields[6] as DateTime,
      uid: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CalculatorHistory obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.weight)
      ..writeByte(2)
      ..write(obj.factorType)
      ..writeByte(3)
      ..write(obj.targetLevel)
      ..writeByte(4)
      ..write(obj.calculatedDose)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.uid);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalculatorHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
