import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_home/core/constants.dart';
import 'package:smart_home/models/device.dart';
import 'package:http/http.dart' as http;
import 'package:smart_home/services/mqtt_service.dart';

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
  }

  return "unknown";
}

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
  }

  return "Unknown";
}

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
    default:
      return returnData ? Icons.device_unknown : Icon(Icons.device_unknown, color: color);
  }
}

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
      return 'Interruptor Inteligente';
    case "trigger":
      return 'Gatilho Inteligente';
    default:
      return 'Dispositivo Desconhecido';
  }
}

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
  "rf": [
    {"icon": FontAwesomeIcons.towerBroadcast, "key": "towerBroadcast"},
    {"icon": FontAwesomeIcons.wifi, "key": "wifi"},
    {"icon": FontAwesomeIcons.signal, "key": "signal"},
    {"icon": FontAwesomeIcons.radio, "key": "radio"},
  ],
  "unknown": [
    {"icon": Icons.device_unknown, "key": "device_unknown"},
    {"icon": Icons.question_mark, "key": "question_mark"},
    {"icon": Icons.help_outline, "key": "help_outline"},
    {"icon": Icons.error_outline, "key": "error_outline"},
  ],
};

Map<String, List<dynamic>> getDeviceTypeIcons() {
  return deviceTypeIcons;
}

Future<String?> _getCurrentSsid() async {
  final info = NetworkInfo();
  final ssid = await info.getWifiName();
  return ssid?.replaceAll('"', '');
}

Future<bool> _sendHttpCommand(Device device, String newState, Duration timeout) async {
  bool ok = false;
  try {
    final uri = Uri.parse('http://${device.ip}:8080/command');
    final response = await http.post(
      uri,
      body: {'state': newState},
    ).timeout(const Duration(seconds: 5));
    ok = response.statusCode == 200;
    print("Resposta HTTP: ${response.statusCode} - ${response.body}");
  } catch (e) {
    ok = false;
    print("Erro ao enviar comando HTTP local: $e");
  }

  return ok;
}

Future<bool> resetDevice(Device device, BuildContext context, bool mounted) async {
  final prefs = await SharedPreferences.getInstance();
  final autoMode = (prefs.getBool(COMM_KEY) ?? true) || device.type == "trigger";

  bool ok = false;

  if (autoMode) {
    final currentSsid = await _getCurrentSsid();
    if (device.ssid == currentSsid) {
      ok = await _sendHttpCommand(device, "clear", const Duration(seconds: 5));
    }
    if (!ok) {
      final mqtt = MqttService();
      ok = await mqtt.publishMessage(device.deviceId, "clear");
    }
  } else {
    ok = await _sendHttpCommand(device, "clear", const Duration(seconds: 5));
  }

  return ok;
}
