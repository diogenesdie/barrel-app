// =============================================================================
// routine.dart
//
// Modelos de Rotina para o barrel-app.
// Espelha os tipos Go: Routine, RoutineTrigger, RoutineAction.
// Online-only — sem cache Hive.
// =============================================================================

/// Gatilho de uma rotina.
/// [type] = "device" ou "schedule".
class RoutineTrigger {
  final String type;
  final int? deviceId;
  final Map<String, String>? expectedState;
  final String? cron;

  const RoutineTrigger({
    required this.type,
    this.deviceId,
    this.expectedState,
    this.cron,
  });

  factory RoutineTrigger.fromJson(Map<String, dynamic> json) {
    return RoutineTrigger(
      type: json['type'] as String,
      deviceId: json['device_id'] as int?,
      expectedState: json['expected_state'] == null
          ? null
          : (json['expected_state'] as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, v as String)),
      cron: json['cron'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (deviceId != null) 'device_id': deviceId,
      if (expectedState != null) 'expected_state': expectedState,
      if (cron != null) 'cron': cron,
    };
  }

  RoutineTrigger copyWith({
    String? type,
    int? deviceId,
    Map<String, String>? expectedState,
    String? cron,
  }) {
    return RoutineTrigger(
      type: type ?? this.type,
      deviceId: deviceId ?? this.deviceId,
      expectedState: expectedState ?? this.expectedState,
      cron: cron ?? this.cron,
    );
  }
}

/// Ação executada quando a rotina dispara.
/// [type] = "device" ou "scene".
class RoutineAction {
  final int id;
  final int routineId;
  final String type;
  final int? deviceId;
  final String? command;
  final int? sceneId;
  final int sortOrder;

  const RoutineAction({
    required this.id,
    required this.routineId,
    required this.type,
    this.deviceId,
    this.command,
    this.sceneId,
    required this.sortOrder,
  });

  factory RoutineAction.fromJson(Map<String, dynamic> json) {
    return RoutineAction(
      id: json['id'] as int,
      routineId: json['routine_id'] as int,
      type: json['type'] as String,
      deviceId: json['device_id'] as int?,
      command: json['command'] as String?,
      sceneId: json['scene_id'] as int?,
      sortOrder: json['sort_order'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routine_id': routineId,
      'type': type,
      if (deviceId != null) 'device_id': deviceId,
      if (command != null) 'command': command,
      if (sceneId != null) 'scene_id': sceneId,
      'sort_order': sortOrder,
    };
  }

  RoutineAction copyWith({
    int? id,
    int? routineId,
    String? type,
    int? deviceId,
    String? command,
    int? sceneId,
    int? sortOrder,
  }) {
    return RoutineAction(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      type: type ?? this.type,
      deviceId: deviceId ?? this.deviceId,
      command: command ?? this.command,
      sceneId: sceneId ?? this.sceneId,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

/// Rotina — sequência automatizada de ações disparada por evento ou agendamento.
class Routine {
  final int id;
  final int userId;
  final String name;
  final bool enabled;
  final RoutineTrigger trigger;
  final List<RoutineAction> actions;

  const Routine({
    required this.id,
    required this.userId,
    required this.name,
    required this.enabled,
    required this.trigger,
    required this.actions,
  });

  factory Routine.fromJson(Map<String, dynamic> json) {
    return Routine(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      name: json['name'] as String,
      enabled: json['enabled'] as bool,
      trigger: RoutineTrigger.fromJson(
          json['trigger'] as Map<String, dynamic>),
      actions: (json['actions'] as List<dynamic>? ?? [])
          .map((a) => RoutineAction.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'enabled': enabled,
      'trigger': trigger.toJson(),
      'actions': actions.map((a) => a.toJson()).toList(),
    };
  }

  Routine copyWith({
    int? id,
    int? userId,
    String? name,
    bool? enabled,
    RoutineTrigger? trigger,
    List<RoutineAction>? actions,
  }) {
    return Routine(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      trigger: trigger ?? this.trigger,
      actions: actions ?? this.actions,
    );
  }
}
