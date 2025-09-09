import 'package:hive/hive.dart';

part 'device.g.dart';

@HiveType(typeId: 0)
class Device extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String type;

  @HiveField(3)
  String ip;

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.ip,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      ip: json['ip'],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "type": type,
        "ip": ip,
      };
}
