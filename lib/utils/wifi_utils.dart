import 'package:flutter/services.dart';

class WifiUtils {
  static const platform = MethodChannel('wifi_info_channel');

  static Future<int?> getWifiFrequency() async {
    try {
      final int freq = await platform.invokeMethod('getWifiFrequency');
      return freq; // Em MHz
    } on PlatformException catch (e) {
      print("Erro ao obter frequência do Wi-Fi: ${e.message}");
      return null;
    }
  }

  static Future<bool> is5GHz() async {
    final freq = await getWifiFrequency();
    if (freq == null) return false;
    return freq >= 4900; // Faixa típica de 5 GHz
  }
}
