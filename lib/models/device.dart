import 'package:hive/hive.dart';
import 'package:smart_home/models/device_action.dart';

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

  @HiveField(7, defaultValue: false)
  bool isFavorite;

  @HiveField(8)
  String ssid;

  @HiveField(9)
  String communicationMode;

  @HiveField(10)
  int? groupId;

  @HiveField(11, defaultValue: false)
  bool isShared;

  @HiveField(12, defaultValue: "")
  String icon;

  @HiveField(13, defaultValue: "")
  String owner_username;

  @HiveField(14)
  List<DeviceAction>? actions;

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
    this.actions,
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
      actions: (json['actions'] as List?)
          ?.map((a) => DeviceAction.fromJson(a))
          .toList(),
    );
  }

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
    List<DeviceAction>? actions,
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
      actions: actions ?? this.actions,
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
        if (actions != null)
          "actions": actions!.map((a) => a.toJson()).toList(),
      };

  Map<String, dynamic> toJsonWithId() => {
        "id": id,
        "device_id": deviceId,
        "type": type,
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
        if (actions != null)
          "actions": actions!.map((a) => a.toJson()).toList(),
      };
}