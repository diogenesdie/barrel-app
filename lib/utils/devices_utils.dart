// =============================================================================
// devices_utils.dart
//
// Funções utilitárias para identificação e exibição de dispositivos Barrel.
//
// Conteúdo:
//   - Identificação de tipo e nome padrão pelo deviceId do firmware
//   - Mapeamento de tipo para ícone e subtítulo descritivo
//   - Catálogo de ícones customizáveis por tipo de dispositivo
//   - Envio de comandos HTTP/MQTT (utilitários internos)
//   - Tradução de nomes de ação (PT → comando de firmware e vice-versa)
//   - Catálogo de ícones para botões de controle remoto
// =============================================================================

// Flutter
import 'package:flutter/material.dart';

// Terceiros
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Projeto — core e modelos
import 'package:smart_home/core/constants.dart';
import 'package:smart_home/models/device.dart';

// Projeto — serviços e utils
import 'package:smart_home/services/mqtt_service.dart';
import 'package:smart_home/utils/crypto_utils.dart';

// SECTION: Identificação de dispositivo por ID do firmware

/// Retorna o tipo canônico do dispositivo com base em seu [id] de firmware.
///
/// Exemplos: "ESP_PLUG_01" → "plug", "ESP_LIGHT_01" → "light"
String getDeviceType(String id) {
  if (id.contains("PLUG")) {
    return "plug";
  } else if (id.contains("LIGHT")) {
    return "light";
  } else if (id.contains("SWITCH")) {
    return "switch";
  } else if (id.contains("TRIGGER")) {
    return "trigger";
  } else if (id.contains("RF")) {
    return "rf";
  } else if (id.contains("FEEDER")) {
    return "feeder";
  } else if (id.contains("IR")) {
    return "ir";
  } else if (id.contains("CONTACT")) {
    return "contact";
  }

  return "unknown";
}

// SECTION: Nome padrão por ID do firmware

/// Retorna o nome de exibição padrão do dispositivo com base em seu [id] de firmware.
String getDeviceName(String id) {
  if (id.contains("PLUG")) {
    return "Barrel Plug";
  } else if (id.contains("LIGHT")) {
    return "Barrel Light";
  } else if (id.contains("SWITCH")) {
    return "Barrel Switch";
  } else if (id.contains("TRIGGER")) {
    return "Barrel Trigger";
  } else if (id.contains("RF")) {
    return "Barrel RF Controller";
  } else if (id.contains("FEEDER")) {
    return "Barrel Feeder";
  } else if (id.contains("IR")) {
    return "Barrel IR Controller";
  } else if (id.contains("CONTACT")) {
    return "Barrel Contact Sensor";
  }

  return "Unknown";
}

// SECTION: Ícone padrão por tipo

/// Retorna a chave do ícone padrão para o [type] especificado.
/// A chave corresponde a uma entrada no [deviceTypeIcons].
String getDefaultIconNameByType(String type) {
  switch (type) {
    case "plug":
      return "plug";
    case "light":
      return "lightbulb";
    case "switch":
      return "powerOff";
    case "trigger":
      return "bolt";
    case "rf":
      return "towerBroadcast";
    case "feeder":
      return "bowlFood";
    case "ir":
      return "forward";
    case "contact":
      return "doorOpen";
    default:
      return "device_unknown";
  }
}

// SECTION: Resolução de ícone (custom ou padrão)

/// Retorna o ícone do [device], respeitando a customização do usuário.
///
/// [device] pode ser um [Device] ou uma [String] com o tipo.
/// Se [returnData] for true, retorna o [IconData] puro; caso contrário, retorna um [Icon].
dynamic getDeviceIcon(dynamic device, {Color color = Colors.white, bool returnData = false}) {
  var type = "unknown";
  var icon = "";
  if (device is String) {
    type = device;
  } else if (device is Device) {
    type = device.type;
    icon = device.icon;
  } else {
    return returnData ? Icons.device_unknown : Icon(Icons.device_unknown, color: color);
  }

  if (icon.isNotEmpty) {
    final customIcon = deviceTypeIcons[type]?.firstWhere(
      (e) => e['key'] == icon,
      orElse: () => null,
    );

    if (customIcon != null) {
      return returnData ? customIcon['icon'] : Icon(customIcon['icon'], color: color);
    }
  }

  switch (type) {
    case "plug":
      return returnData ? FontAwesomeIcons.plug : Icon(FontAwesomeIcons.plug, color: color);
    case "lightbulb":
    case "light":
      return returnData ? FontAwesomeIcons.lightbulb : Icon(FontAwesomeIcons.lightbulb, color: color);
    case "switch":
      return returnData ? FontAwesomeIcons.powerOff : Icon(FontAwesomeIcons.powerOff, color: color);
    case "trigger":
      return returnData ? FontAwesomeIcons.bolt : Icon(FontAwesomeIcons.bolt, color: color);
    case "rf":
      return returnData ? FontAwesomeIcons.towerBroadcast : Icon(FontAwesomeIcons.towerBroadcast, color: color);
    case "feeder":
      return returnData ? FontAwesomeIcons.bowlFood : Icon(FontAwesomeIcons.bowlFood, color: color);
    case "ir":
      return returnData ? FontAwesomeIcons.forward : Icon(FontAwesomeIcons.forward, color: color);
    case "contact":
      return returnData ? FontAwesomeIcons.doorOpen : Icon(FontAwesomeIcons.doorOpen, color: color);
    default:
      return returnData ? Icons.device_unknown : Icon(Icons.device_unknown, color: color);
  }
}

// SECTION: Ícone de grupo

/// Retorna o [IconData] correspondente ao nome de ícone de um grupo.
IconData getGroupIconData(String iconName) {
  switch (iconName) {
    case "house":
      return FontAwesomeIcons.house;
    case "work":
      return FontAwesomeIcons.briefcase;
    case "favorite":
      return FontAwesomeIcons.heart;
    case "gym":
      return FontAwesomeIcons.dumbbell;
    case "school":
      return FontAwesomeIcons.school;
    case "cafe":
      return FontAwesomeIcons.coffee;
    case "car":
      return FontAwesomeIcons.car;
    case "travel":
      return FontAwesomeIcons.plane;
    case "garden":
      return FontAwesomeIcons.seedling;
    case "pets":
      return FontAwesomeIcons.paw;
    case "share":
      return FontAwesomeIcons.shareNodes;
    default:
      return FontAwesomeIcons.layerGroup; // ícone padrão
  }
}

// SECTION: Subtítulo descritivo por tipo

/// Retorna uma descrição amigável do tipo de dispositivo para exibição na UI.
String getDeviceSubtitle(String type) {
  switch (type) {
    case "feeder":
      return 'Alimentador Automático';
    case "rf":
      return 'Controle RF Inteligente';
    case "lightbulb":
    case "light":
      return 'Lâmpada Inteligente';
    case "switch":
      return 'Tomada Inteligente';
    case "trigger":
      return 'Interruptor Inteligente';
    case "ir":
      return 'Controle Universal Inteligente';
    case "contact":
      return 'Sensor de Contato Inteligente';
    default:
      return 'Dispositivo Desconhecido';
  }
}

// SECTION: Catálogo de ícones disponíveis por tipo de dispositivo

/// Mapa de ícones customizáveis por tipo de dispositivo.
///
/// Cada entrada contém uma lista de opções no formato `{"icon": IconData, "key": String}`.
/// A chave [key] é persistida em [Device.icon]; o [icon] é o [IconData] exibido.
Map<String, List<dynamic>> deviceTypeIcons = {
  "plug": [
    {"icon": FontAwesomeIcons.plug, "key": "plug"},
    {"icon": FontAwesomeIcons.bolt, "key": "bolt"},
  ],
  "light": [
    {"icon": FontAwesomeIcons.lightbulb, "key": "lightbulb"},
    {"icon": FontAwesomeIcons.solidLightbulb, "key": "solidLightbulb"},
  ],
  "switch": [
    {"icon": FontAwesomeIcons.powerOff, "key": "powerOff"},
    {"icon": FontAwesomeIcons.toggleOn, "key": "toggleOn"},
    {"icon": FontAwesomeIcons.plug, "key": "plug"},
    {"icon": FontAwesomeIcons.lightbulb, "key": "lightbulb"},
  ],
  "trigger": [
    {"icon": FontAwesomeIcons.bolt, "key": "bolt"},
    {"icon": FontAwesomeIcons.bell, "key": "bell"},
    {"icon": FontAwesomeIcons.bullhorn, "key": "bullhorn"},
    {"icon": FontAwesomeIcons.triangleExclamation, "key": "triangleExclamation"},
  ],
  "feeder": [
    {"icon": FontAwesomeIcons.bowlFood, "key": "bowlFood"},
    {"icon": FontAwesomeIcons.bone, "key": "bone"},
    {"icon": FontAwesomeIcons.dog, "key": "dog"},
    {"icon": FontAwesomeIcons.cat, "key": "cat"},
    {"icon": FontAwesomeIcons.clock, "key": "clock"},
    {"icon": FontAwesomeIcons.utensils, "key": "utensils"},
  ],
  "rf": [
    {"icon": FontAwesomeIcons.towerBroadcast, "key": "towerBroadcast"},
    {"icon": FontAwesomeIcons.wifi, "key": "wifi"},
    {"icon": FontAwesomeIcons.signal, "key": "signal"},
  ],
  "ir": [
    {"icon": FontAwesomeIcons.forward, "key": "forward"},
    {"icon": FontAwesomeIcons.tv, "key": "tv"},
    {"icon": FontAwesomeIcons.fan, "key": "fan"},
    {"icon": FontAwesomeIcons.snowflake, "key": "snowflake"},
  ],
  "contact": [
    {"icon": FontAwesomeIcons.doorOpen, "key": "doorOpen"},
    {"icon": FontAwesomeIcons.doorClosed, "key": "doorClosed"},
    {"icon": FontAwesomeIcons.houseChimney, "key": "houseChimney"},
  ],
  "unknown": [
    {"icon": Icons.device_unknown, "key": "device_unknown"},
    {"icon": Icons.question_mark, "key": "question_mark"},
    {"icon": Icons.help_outline, "key": "help_outline"},
    {"icon": Icons.error_outline, "key": "error_outline"},
  ],
};

/// Retorna o mapa completo de ícones por tipo. Atalho para [deviceTypeIcons].
Map<String, List<dynamic>> getDeviceTypeIcons() {
  return deviceTypeIcons;
}

// SECTION: Utilitários internos de comunicação HTTP/MQTT

/// Retorna o SSID da rede Wi-Fi atual, ou null se indisponível.
///
/// Nota: função equivalente existe em button_sender_service.dart e your_home_page.dart.
Future<String?> _getCurrentSsid() async {
  final info = NetworkInfo();
  final ssid = await info.getWifiName();
  return ssid?.replaceAll('"', '');
}

/// Envia [newState] criptografado ao firmware do [device] via HTTP (porta 8080).
///
/// Nota: função equivalente existe em button_sender_service.dart e your_home_page.dart.
Future<bool> _sendHttpCommand(Device device, String newState, Duration timeout) async {
  bool ok = false;
  try {
    final encryptedData = encryptData(
      device.ivKey.split(':')[0],
      device.ivKey.split(':')[1],
      newState,
    );
    final uri = Uri.parse('http://${device.ip}:8080/command');
    final response = await http
        .post(
          uri,
          body: encryptedData,
        )
        .timeout(const Duration(seconds: 5));
    ok = response.statusCode == 200;
  } catch (e) {
    ok = false;
    print("Erro ao enviar comando HTTP local: $e");
  }

  return ok;
}

/// Envia o comando "clear" ao [device] para redefinir suas configurações.
/// Usa HTTP local se na mesma rede Wi-Fi; caso contrário, usa MQTT.
Future<bool> resetDevice(Device device, BuildContext context, bool mounted) async {
  final prefs = await SharedPreferences.getInstance();
  final autoMode = (prefs.getBool(COMM_KEY) ?? true) || device.type == "trigger";

  bool ok = false;

  if (autoMode) {
    print("Tentando resetar via HTTP local...");
    final currentSsid = await _getCurrentSsid();
    if (device.ssid == currentSsid) {
      ok = await _sendHttpCommand(device, "clear", const Duration(seconds: 5));
    }
    if (!ok) {
      print("Tentando resetar via MQTT...");
      final mqtt = MqttService();
      ok = await mqtt.publishMessage(device.id, device.deviceId, "clear");
    }
  } else {
    print("Tentando resetar via HTTP local (modo manual)...");
    ok = await _sendHttpCommand(device, "clear", const Duration(seconds: 5));
    print(ok ? "Reset via HTTP local bem-sucedido." : "Falha no reset via HTTP local.");
  }

  return ok;
}

// SECTION: Ações disponíveis por tipo e tradução de comandos

/// Retorna a lista de ações disponíveis (em português) para o [type] de dispositivo.
List<String> getActionsForType(String type) {
  switch (type.toLowerCase()) {
    case 'switch':
      return ['Ligar', 'Desligar', 'Alternar'];
    case 'rf':
      return ['Pulsar'];
    case 'feeder':
      return ['Liberar'];
    default:
      return ['Ligar', 'Desligar', 'Alternar', 'Pulsar', 'Liberar'];
  }
}

/// Traduz o nome de ação em português para o comando do firmware (ex.: "Ligar" → "on").
String getActionCommand(String action) {
  switch (action.toLowerCase()) {
    case 'ligar':
      return 'on';
    case 'desligar':
      return 'off';
    case 'alternar':
      return 'toggle';
    case 'pulsar':
      return 'pulse';
    case 'liberar':
      return 'release';
    default:
      return action.toLowerCase();
  }
}

/// Traduz o comando do firmware para o nome de ação em português (ex.: "on" → "Ligar").
/// Retorna null se o comando não tiver mapeamento.
String? getActionDisplayName(String command) {
  switch (command.toLowerCase()) {
    case 'on':
      return 'Ligar';
    case 'off':
      return 'Desligar';
    case 'toggle':
      return 'Alternar';
    case 'pulse':
      return 'Pulsar';
    case 'release':
      return 'Liberar';
    default:
      return null;
  }
}

// SECTION: Catálogo de ícones para botões de controle remoto

/// Mapa de ícones disponíveis para botões de controle remoto IR/RF.
/// A chave string é persistida em [DeviceButton.icon].
final Map<String, IconData> buttonsIcons = {
  "power": FontAwesomeIcons.powerOff,
  "tv": FontAwesomeIcons.tv,
  "volume_up": FontAwesomeIcons.volumeHigh,
  "volume_down": FontAwesomeIcons.volumeLow,
  "play": FontAwesomeIcons.play,
  "pause": FontAwesomeIcons.pause,
  "forward": FontAwesomeIcons.forward,
  "back": FontAwesomeIcons.backward,
  "light": FontAwesomeIcons.lightbulb,
  "fan": FontAwesomeIcons.fan,
  "snow": FontAwesomeIcons.snowflake,
  "wifi": FontAwesomeIcons.wifi,
  "bolt": FontAwesomeIcons.bolt,
  "bars": FontAwesomeIcons.bars,
  "circle": Icons.circle,
  "stop": FontAwesomeIcons.stop,
  "x": FontAwesomeIcons.xmark,
  "empty": Icons.block,
};
