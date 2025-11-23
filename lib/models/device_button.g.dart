// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_button.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeviceButtonAdapter extends TypeAdapter<DeviceButton> {
  @override
  final int typeId = 3;

  @override
  DeviceButton read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeviceButton(
      id: fields[0] as int,
      originalName: fields[1] as String,
      protocol: fields[2] as String,
      address: fields[3] as int,
      command: fields[4] as int,
      label: fields[5] as String,
      color: fields[6] as int,
      icon: fields[7] as String,
      deviceId: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DeviceButton obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.originalName)
      ..writeByte(2)
      ..write(obj.protocol)
      ..writeByte(3)
      ..write(obj.address)
      ..writeByte(4)
      ..write(obj.command)
      ..writeByte(5)
      ..write(obj.label)
      ..writeByte(6)
      ..write(obj.color)
      ..writeByte(7)
      ..write(obj.icon)
      ..writeByte(8)
      ..write(obj.deviceId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceButtonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
