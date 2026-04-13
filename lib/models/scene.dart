// =============================================================================
// scene.dart
//
// Modelo de Cena Barrel.
// Uma cena agrupa múltiplas ações em dispositivos executadas de forma atômica.
// Exemplo: "Modo Cinema" → desliga lâmpada + liga TV.
//
// Online-only: não utiliza Hive para cache local.
// =============================================================================

/// Ação individual de uma cena — representa um comando enviado a um dispositivo.
class SceneAction {
  final int id;
  final int sceneId;
  final int deviceId;
  final String command;
  final int sortOrder;

  const SceneAction({
    required this.id,
    required this.sceneId,
    required this.deviceId,
    required this.command,
    required this.sortOrder,
  });

  factory SceneAction.fromJson(Map<String, dynamic> json) {
    return SceneAction(
      id: json['id'] ?? 0,
      sceneId: json['scene_id'] ?? 0,
      deviceId: json['device_id'],
      command: json['command'],
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'scene_id': sceneId,
        'device_id': deviceId,
        'command': command,
        'sort_order': sortOrder,
      };

  SceneAction copyWith({
    int? id,
    int? sceneId,
    int? deviceId,
    String? command,
    int? sortOrder,
  }) {
    return SceneAction(
      id: id ?? this.id,
      sceneId: sceneId ?? this.sceneId,
      deviceId: deviceId ?? this.deviceId,
      command: command ?? this.command,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

/// Cena: conjunto nomeado de ações em dispositivos acionado com um único toque.
class Scene {
  final int id;
  final int userId;
  final String name;
  final String? icon;
  final List<SceneAction> actions;

  const Scene({
    required this.id,
    required this.userId,
    required this.name,
    this.icon,
    this.actions = const [],
  });

  factory Scene.fromJson(Map<String, dynamic> json) {
    final rawActions = json['actions'] as List<dynamic>? ?? [];
    return Scene(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['name'],
      icon: json['icon'] as String?,
      actions: rawActions
          .map((a) => SceneAction.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        if (icon != null) 'icon': icon,
        'actions': actions.map((a) => a.toJson()).toList(),
      };

  Scene copyWith({
    int? id,
    int? userId,
    String? name,
    String? icon,
    List<SceneAction>? actions,
  }) {
    return Scene(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      actions: actions ?? this.actions,
    );
  }
}
