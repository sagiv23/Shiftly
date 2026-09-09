// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wage_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WageEntryAdapter extends TypeAdapter<WageEntry> {
  @override
  final int typeId = 4;

  @override
  WageEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WageEntry(
      startDate: fields[0] as DateTime,
      hourlyRate: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, WageEntry obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.startDate)
      ..writeByte(1)
      ..write(obj.hourlyRate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WageEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
