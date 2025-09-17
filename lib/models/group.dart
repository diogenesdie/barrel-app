import 'package:hive/hive.dart';

part 'group.g.dart';

@HiveType(typeId: 1)
class Group extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int position;

  @HiveField(3)
  String icon;

  @HiveField(4)
  bool isDefault = false;

  Group({
    required this.id,
    required this.name,
    this.position = 0,
    this.icon = '',
    this.isDefault = false,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      position: json['position'] ?? 0,
      icon: json['icon'] ?? '',
      isDefault: json['is_default'] ?? false,
    );
  }

  Group copyWith({
    int? id,
    String? name,
    int? position,
    String? icon,
    bool? isDefault,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        "name": name,
        "position": position,
        "icon": icon,
        "is_default": isDefault,
      };
}
