// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeviceAdapter extends TypeAdapter<Device> {
  @override
  final int typeId = 0;

  @override
  Device read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Device(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as String,
      ip: fields[3] as String,
      ivKey: fields[4] as String,
      state: fields[5] as String,
      ssid: fields[7] as String,
      communicationMode: fields[8] as String,
      groupId: fields[9] as int?,
      isFavorite: fields[6] as bool,
      isShared: fields[10] as bool,
      icon: fields[11] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Device obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.ip)
      ..writeByte(4)
      ..write(obj.ivKey)
      ..writeByte(5)
      ..write(obj.state)
      ..writeByte(6)
      ..write(obj.isFavorite)
      ..writeByte(7)
      ..write(obj.ssid)
      ..writeByte(8)
      ..write(obj.communicationMode)
      ..writeByte(9)
      ..write(obj.groupId)
      ..writeByte(10)
      ..write(obj.isShared)
      ..writeByte(11)
      ..write(obj.icon);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
