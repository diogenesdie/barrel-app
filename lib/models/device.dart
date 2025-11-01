import 'package:hive/hive.dart';

part 'device.g.dart';

@HiveType(typeId: 0)
class Device extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String deviceId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String type;

  @HiveField(4)
  String ip;

  @HiveField(5)
  String ivKey;

  @HiveField(6)
  String state;

  @HiveField(7)
  bool isFavorite = false;

  @HiveField(8)
  String ssid;

  @HiveField(9)
  String communicationMode; // "auto" ou "local"

  @HiveField(10)
  int? groupId;

  @HiveField(11)
  bool isShared = false;

  @HiveField(12)
  String icon = "";

  @HiveField(13)
  String owner_username = "";

  Device({
    required this.id,
    required this.deviceId,
    required this.name,
    required this.type,
    required this.ip,
    required this.ivKey,
    required this.state,
    required this.ssid,
    required this.communicationMode,
    this.groupId,
    this.isFavorite = false,
    this.isShared = false,
    this.icon = "",
    this.owner_username = "",
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      deviceId: json['device_id'],
      name: json['name'],
      type: json['type'],
      ip: json['ip'],
      ivKey: json['iv_key'] ?? '',
      state: json['state'] ?? 'off',
      isFavorite: json['is_favorite'] ?? false,
      ssid: json['ssid'] ?? '',
      communicationMode: json['communication_mode'] ?? 'auto',
      groupId: json['group_id'],
      isShared: json['is_shared'] ?? false,
      icon: json['icon'] ?? '',
      owner_username: json['owner_username'] ?? '',
    );
  }

  //copyWith method
  Device copyWith({
    int? id,
    String? deviceId,
    String? name,
    String? type,
    String? ip,
    String? ivKey,
    String? state,
    bool? isFavorite,
    String? ssid,
    String? communicationMode,
    int? groupId,
    bool? isShared,
    String? icon,
    String? owner_username,
  }) {
    return Device(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      type: type ?? this.type,
      ip: ip ?? this.ip,
      ivKey: ivKey ?? this.ivKey,
      state: state ?? this.state,
      isFavorite: isFavorite ?? this.isFavorite,
      ssid: ssid ?? this.ssid,
      communicationMode: communicationMode ?? this.communicationMode,
      groupId: groupId ?? this.groupId,
      isShared: isShared ?? this.isShared,
      icon: icon ?? this.icon,
      owner_username: owner_username ?? this.owner_username,
    );
  }

  Map<String, dynamic> toJson() => {
        "device_id": deviceId,
        "name": name,
        "type": type,
        "ip": ip,
        "iv_key": ivKey,
        "state": state,
        "is_favorite": isFavorite,
        "ssid": ssid,
        "communication_mode": communicationMode,
        "group_id": groupId,
        "is_shared": isShared,
        "icon": icon,
        "owner_username": owner_username,
      };

    Map<String, dynamic> toJsonWithId() => {
        "id": id,
        "device_id": deviceId,
        "name": name,
        "ip": ip,
        "iv_key": ivKey,
        "state": state,
        "is_favorite": isFavorite,
        "ssid": ssid,
        "communication_mode": communicationMode,
        "group_id": groupId,
        "is_shared": isShared,
        "icon": icon,
        "owner_username": owner_username,
      };
}
