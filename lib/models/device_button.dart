// =============================================================================
// device_button.dart
//
// Modelo de botão de um controle remoto IR/RF.
// Cada botão pertence a um [Device] e armazena o código de protocolo
// enviado pelo [ButtonSenderService].
// Persistido via Hive (typeId: 3).
// =============================================================================

import 'package:hive/hive.dart';

part 'device_button.g.dart';

/// Representa um botão de controle remoto (IR ou RF) de um dispositivo.
///
/// O campo [originalName] é o identificador fixo do firmware e nunca deve
/// ser alterado. O campo [label] é a versão editável exibida ao usuário.
@HiveType(typeId: 3)
class DeviceButton extends HiveObject {
  @HiveField(0)
  int id;

  /// Identificador fixo do firmware (ex.: "BTN_1"). NÃO ALTERAR após o cadastro.
  @HiveField(1)
  String originalName;

  @HiveField(2)
  String protocol;

  @HiveField(3)
  int address;

  @HiveField(4)
  int command;

  /// Nome editável exibido ao usuário na tela de controle remoto.
  @HiveField(5)
  String label;

  /// Cor do botão em formato ARGB (ex.: 0xFF1E1E1E).
  @HiveField(6)
  int color;

  /// Nome do ícone selecionado pelo usuário, ou vazio para exibir apenas o label.
  @HiveField(7)
  String icon;

  /// Referência ao [Device] pai ao qual este botão pertence.
  @HiveField(8)
  int deviceId;

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

  /// Constrói um [DeviceButton] a partir do JSON retornado pelo firmware do dispositivo.
  /// Aplica valores padrão de cor e ícone que podem ser customizados pelo usuário depois.
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
