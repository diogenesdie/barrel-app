// =============================================================================
// device_action.dart
//
// Modelo de automação entre dispositivos.
// Define que, quando um dispositivo (trigger) recebe um evento, outro
// dispositivo (target) executa uma ação.
// Persistido via Hive (typeId: 2) como parte do [Device.actions].
// =============================================================================

import 'package:hive/hive.dart';

part 'device_action.g.dart';

/// Define uma automação entre dois dispositivos.
///
/// Exemplo: quando o sensor de porta (trigger) detectar abertura (triggerEvent "open"),
/// a lâmpada (target) deve executar a ação "turnOn" (actionType).
@HiveType(typeId: 2)
class DeviceAction extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  int triggerDeviceId;

  @HiveField(2)
  String triggerEvent;

  @HiveField(3)
  int targetDeviceId;

  @HiveField(4)
  String actionType;

  @HiveField(5)
  String targetDeviceName;

  @HiveField(6)
  String targetDeviceIp;

  @HiveField(7)
  String targetDeviceQueue;

  DeviceAction({
    required this.id,
    required this.triggerDeviceId,
    required this.triggerEvent,
    required this.targetDeviceId,
    required this.actionType,
    required this.targetDeviceName,
    required this.targetDeviceIp,
    required this.targetDeviceQueue,
  });

  /// Constrói um [DeviceAction] a partir do JSON retornado pela API REST.
  factory DeviceAction.fromJson(Map<String, dynamic> json) {
    return DeviceAction(
      id: json['id'],
      triggerDeviceId: json['trigger_device_id'],
      triggerEvent: json['trigger_event'],
      targetDeviceId: json['target_device_id'],
      actionType: json['action_type'],
      targetDeviceName: json['target_device_name'] ?? '',
      targetDeviceIp: json['target_device_ip'] ?? '',
      targetDeviceQueue: json['target_device_queue'] ?? '',
    );
  }

  /// Serializa para JSON incluindo apenas os campos necessários para a API.
  /// Campos de exibição (targetDeviceName, ip, queue) são omitidos.
  Map<String, dynamic> toJson() => {
        "trigger_device_id": triggerDeviceId,
        "trigger_event": triggerEvent,
        "target_device_id": targetDeviceId,
        "action_type": actionType
      };
}
