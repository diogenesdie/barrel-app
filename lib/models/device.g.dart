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
      id: fields[0] as int,
      deviceId: fields[1] as String,
      name: fields[2] as String,
      type: fields[3] as String,
      ip: fields[4] as String,
      ivKey: fields[5] as String,
      state: fields[6] as String,
      ssid: fields[8] as String,
      communicationMode: fields[9] as String,
      groupId: fields[10] as int?,
      isFavorite: fields[7] as bool,
      isShared: fields[11] as bool,
      icon: fields[12] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Device obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.deviceId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.ip)
      ..writeByte(5)
      ..write(obj.ivKey)
      ..writeByte(6)
      ..write(obj.state)
      ..writeByte(7)
      ..write(obj.isFavorite)
      ..writeByte(8)
      ..write(obj.ssid)
      ..writeByte(9)
      ..write(obj.communicationMode)
      ..writeByte(10)
      ..write(obj.groupId)
      ..writeByte(11)
      ..write(obj.isShared)
      ..writeByte(12)
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
