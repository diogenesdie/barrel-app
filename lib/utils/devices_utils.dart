import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

String getDeviceType(String id) {
  if (id.contains("PLUG")) {
    return "plug";
  } else if (id.contains("LIGHT")) {
    return "light";
  } else if (id.contains("SWITCH")) {
    return "switch";
  } else if (id.contains("TRIGGER")) {
    return "trigger";
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
  }

  return "Unknown";
}

dynamic getDeviceIcon(String type, {Color color = Colors.white, bool returnData = false}) {
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
    default:
      return FontAwesomeIcons.layerGroup; // ícone padrão
  }
}

String getDeviceSubtitle(String type) {
  switch (type) {
    case "plug":
      return "Tomada Inteligente";
    case "light":
      return "Lâmpada Inteligente";
    case "switch":
      return "Interruptor Inteligente";
    case "trigger":
      return "Gatilho Inteligente";
    default:
      return "Unknown";
  }
}