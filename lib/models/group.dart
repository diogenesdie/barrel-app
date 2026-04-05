// =============================================================================
// group.dart
//
// Modelo de grupo de dispositivos.
// Grupos organizam dispositivos em categorias (ex.: sala, quarto).
// Persistido via Hive (typeId: 1) e sincronizado com a API REST.
// =============================================================================

import 'package:hive/hive.dart';

part 'group.g.dart';

/// Representa um grupo (cômodo/categoria) que organiza dispositivos na interface.
///
/// Persistido no Hive com typeId 1. A sincronização com a API REST é feita
/// por [GroupRepository].
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

  /// Constrói um [Group] a partir de um JSON retornado pela API REST.
  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      position: json['position'] ?? 0,
      icon: json['icon'] ?? '',
      isDefault: json['is_default'] ?? false,
    );
  }

  /// Retorna uma cópia com os campos especificados substituídos.
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

  /// Serializa para JSON (sem o campo 'id', usado em criação e atualização).
  Map<String, dynamic> toJson() => {
        "name": name,
        "position": position,
        "icon": icon,
        "is_default": isDefault,
      };
}
