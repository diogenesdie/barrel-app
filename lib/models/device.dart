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

  @HiveField(4)
  String ivKey;

  @HiveField(5)
  String state;

  @HiveField(6)
  bool isFavorite = false;

  @HiveField(7)
  String ssid;

  @HiveField(8)
  String communicationMode; // "auto" ou "local"

  @HiveField(9)
  int? groupId;

  @HiveField(10)
  bool isShared = false;

  @HiveField(11)
  String icon = "";

  Device({
    required this.id,
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
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      ip: json['ip'],
      ivKey: json['ivKey'] ?? '',
      state: json['state'] ?? 'off',
      isFavorite: json['isFavorite'] ?? false,
      ssid: json['ssid'] ?? '',
      communicationMode: json['communicationMode'] ?? 'auto',
      groupId: json['groupId'],
      isShared: json['isShared'] ?? false,
      icon: json['icon'] ?? '',
    );
  }

  //copyWith method
  Device copyWith({
    String? id,
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
  }) {
    return Device(
      id: id ?? this.id,
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
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "type": type,
        "ip": ip,
        "ivKey": ivKey,
        "state": state,
        "isFavorite": isFavorite,
        "ssid": ssid,
        "communicationMode": communicationMode,
        "groupId": groupId,
        "isShared": isShared,
        "icon": icon,
      };
}
