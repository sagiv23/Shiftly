// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class JobTypeAdapter extends TypeAdapter<JobType> {
  @override
  final int typeId = 0;

  @override
  JobType read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JobType(
      id: fields[0] as String,
      name: fields[1] as String,
      hourlyRate: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, JobType obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.hourlyRate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JobTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
