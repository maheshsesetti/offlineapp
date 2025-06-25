// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttendanceModelAdapter extends TypeAdapter<AttendanceModel> {
  @override
  final int typeId = 0;

  @override
  AttendanceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AttendanceModel(
      name: fields[0] as String?,
      checkIn: fields[1] as DateTime?,
      checkOut: fields[2] as DateTime?,
      checkInLatitude: fields[3] as double?,
      checkInLongitude: fields[4] as double?,
      checkOutLatitude: fields[5] as double?,
      checkOutLongitude: fields[6] as double?,
      date: fields[7] as String?,
      isCheckIn: fields[8] as bool?,
      isCheckedout: fields[9] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, AttendanceModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.checkIn)
      ..writeByte(2)
      ..write(obj.checkOut)
      ..writeByte(3)
      ..write(obj.checkInLatitude)
      ..writeByte(4)
      ..write(obj.checkInLongitude)
      ..writeByte(5)
      ..write(obj.checkOutLatitude)
      ..writeByte(6)
      ..write(obj.checkOutLongitude)
      ..writeByte(7)
      ..write(obj.date)
      ..writeByte(8)
      ..write(obj.isCheckIn)
      ..writeByte(9)
      ..write(obj.isCheckedout);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
