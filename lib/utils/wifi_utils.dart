// =============================================================================
// wifi_utils.dart
//
// Utilitários para inspeção da rede Wi-Fi atual.
// Usa MethodChannel nativo ('wifi_info_channel') para ler a frequência da rede.
//
// Necessário para alertar o usuário sobre redes 5 GHz incompatíveis com
// os dispositivos Barrel (que suportam apenas 2.4 GHz).
// =============================================================================

// Flutter
import 'package:flutter/services.dart';

/// Utilitários para ler informações da rede Wi-Fi via canal nativo.
class WifiUtils {
  static const platform = MethodChannel('wifi_info_channel');

  /// Retorna a frequência da rede Wi-Fi em MHz, ou null se não disponível.
  static Future<int?> getWifiFrequency() async {
    try {
      final int freq = await platform.invokeMethod('getWifiFrequency');
      return freq; // Em MHz
    } on PlatformException catch (e) {
      print("Erro ao obter frequência do Wi-Fi: ${e.message}");
      return null;
    }
  }

  /// Retorna true se a rede Wi-Fi atual opera na faixa de 5 GHz.
  static Future<bool> is5GHz() async {
    final freq = await getWifiFrequency();
    if (freq == null) return false;
    return freq >= 4900; // Faixa típica de 5 GHz
  }
}
