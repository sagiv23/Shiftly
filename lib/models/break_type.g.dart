// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'break_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BreakTypeAdapter extends TypeAdapter<BreakType> {
  @override
  final int typeId = 2;

  @override
  BreakType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BreakType.none;
      case 1:
        return BreakType.paid;
      case 2:
        return BreakType.unpaid;
      default:
        return BreakType.none;
    }
  }

  @override
  void write(BinaryWriter writer, BreakType obj) {
    switch (obj) {
      case BreakType.none:
        writer.writeByte(0);
        break;
      case BreakType.paid:
        writer.writeByte(1);
        break;
      case BreakType.unpaid:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BreakTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
