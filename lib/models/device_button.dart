import 'package:hive/hive.dart';

part 'device_button.g.dart';

@HiveType(typeId: 3)
class DeviceButton extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String originalName; // BTN_1 (NÃO ALTERAR)

  @HiveField(2)
  String protocol;

  @HiveField(3)
  int address;

  @HiveField(4)
  int command;

  @HiveField(5)
  String label; // nome editável pelo user

  @HiveField(6)
  int color; // int ARGB Flutter

  @HiveField(7)
  String icon; // path do icon ou vazio

  @HiveField(8)
  int deviceId; // referencia o device pai

  DeviceButton({
    required this.id,
    required this.originalName,
    required this.protocol,
    required this.address,
    required this.command,
    required this.label,
    required this.color,
    required this.icon,
    required this.deviceId,
  });

  factory DeviceButton.fromJson(Map<String, dynamic> json, int deviceId) {
    return DeviceButton(
      id: json['id'],
      originalName: json['name'],
      protocol: json['protocol'],
      address: json['address'],
      command: json['command'],
      label: json['name'], // default
      color: 0xFF1E1E1E,   // cor padrão do Barrel
      icon: "",
      deviceId: deviceId,
    );
  }
}
