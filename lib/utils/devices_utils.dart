import 'package:flutter/material.dart';

String getDeviceType(String ssid) {
  if (ssid.contains("PLUG")) {
    return "plug";
  } else if (ssid.contains("LIGHT")) {
    return "light";
  } else if (ssid.contains("SWITCH")) {
    return "switch";
  }

  return "unknown";
}

String getDeviceName(String ssid) {
  if (ssid.contains("PLUG")) {
    return "Barrel Plug";
  } else if (ssid.contains("LIGHT")) {
    return "Barrel Light";
  } else if (ssid.contains("SWITCH")) {
    return "Barrel Switch";
  }

  return "Unknown";
}

Icon getDeviceIcon(String type, {Color color = Colors.white}) {
  switch (type) {
    case "plug":
      return Icon(Icons.power, color: color);
    case "light":
      return Icon(Icons.lightbulb, color: color);
    case "switch":
      return Icon(Icons.switch_right, color: color);
    default:
      return Icon(Icons.device_hub, color: color);
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
    default:
      return "Unknown";
  }
}