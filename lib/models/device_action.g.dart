// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_action.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeviceActionAdapter extends TypeAdapter<DeviceAction> {
  @override
  final int typeId = 2;

  @override
  DeviceAction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeviceAction(
      id: fields[0] as int,
      triggerDeviceId: fields[1] as int,
      triggerEvent: fields[2] as String,
      targetDeviceId: fields[3] as int,
      actionType: fields[4] as String,
      targetDeviceName: fields[5] as String,
      targetDeviceIp: fields[6] as String,
      targetDeviceQueue: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DeviceAction obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.triggerDeviceId)
      ..writeByte(2)
      ..write(obj.triggerEvent)
      ..writeByte(3)
      ..write(obj.targetDeviceId)
      ..writeByte(4)
      ..write(obj.actionType)
      ..writeByte(5)
      ..write(obj.targetDeviceName)
      ..writeByte(6)
      ..write(obj.targetDeviceIp)
      ..writeByte(7)
      ..write(obj.targetDeviceQueue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
