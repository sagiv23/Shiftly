// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShiftAdapter extends TypeAdapter<Shift> {
  @override
  final int typeId = 1;

  @override
  Shift read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Shift(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      startTime: fields[2] as DateTime,
      endTime: fields[3] as DateTime,
      jobTypeId: fields[4] as String,
      tips: fields[5] as double,
      breakType: fields[7] as BreakType?,
      unpaidBreakMinutes: fields[8] as double?,
      individualTips: (fields[9] as List?)?.cast<double>(),
    );
  }

  @override
  void write(BinaryWriter writer, Shift obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.startTime)
      ..writeByte(3)
      ..write(obj.endTime)
      ..writeByte(4)
      ..write(obj.jobTypeId)
      ..writeByte(5)
      ..write(obj.tips)
      ..writeByte(7)
      ..write(obj.breakType)
      ..writeByte(8)
      ..write(obj.unpaidBreakMinutes)
      ..writeByte(9)
      ..write(obj.individualTips);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShiftAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
