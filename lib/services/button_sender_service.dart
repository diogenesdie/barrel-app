// =============================================================================
// button_sender_service.dart
//
// Serviço para enviar comandos de botão a dispositivos IR/RF.
//
// Lógica de comunicação híbrida:
//   - Modo "auto":  tenta HTTP local (mesma rede Wi-Fi) primeiro; se falhar,
//                   usa MQTT como fallback remoto.
//   - Modo "local": somente HTTP direto ao firmware (porta 8080).
//
// O modo é lido do SharedPreferences sob a chave "communication_mode".
// O comando é criptografado com AES-CBC antes do envio HTTP (via [encryptData]).
//
// Nota: _sendHttpCommand e _getCurrentSsid também existem em
// your_home_page.dart e devices_utils.dart. Candidatos à consolidação futura.
// =============================================================================

// Terceiros
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Projeto — modelos e serviços
import 'package:smart_home/models/device.dart';
import 'package:smart_home/services/mqtt_service.dart';

// Projeto — utils
import 'package:smart_home/utils/crypto_utils.dart';

/// Serviço responsável por enviar comandos de botão a dispositivos.
///
/// Abstrai o protocolo de comunicação (HTTP local ou MQTT remoto)
/// de acordo com a preferência do usuário e a rede atual.
class ButtonSenderService {
  /// Envia o [newState] criptografado diretamente ao firmware do [device] via HTTP.
  /// Usa AES-CBC com a chave armazenada em [Device.ivKey].
  ///
  /// Nota: função equivalente existe em your_home_page.dart e devices_utils.dart.
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
            headers: {"Content-Type": "text/plain"},
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

  /// Retorna o SSID da rede Wi-Fi atual, ou null se indisponível.
  ///
  /// Nota: função equivalente existe em your_home_page.dart e devices_utils.dart.
  Future<String?> _getCurrentSsid() async {
    final info = NetworkInfo();
    final ssid = await info.getWifiName();
    return ssid?.replaceAll('"', '');
  }
  
  /// Envia o pressionamento de [buttonName] ao [device] usando o modo de comunicação ativo.
  ///
  /// Em modo "auto": tenta HTTP local primeiro; se falhar, usa MQTT.
  /// Em modo "local": somente HTTP.
  Future<void> sendButton({
    required String buttonName,
    required Device device,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString("communication_mode") ?? "auto";
    final autoMode = mode == "auto";
    bool ok = false;

    if (autoMode) {
      final currentSsid = await _getCurrentSsid();
      if (currentSsid == device.ssid) {
        ok = await _sendHttpCommand(device, 'send:$buttonName', Duration(milliseconds: 500));
      }
      if (!ok) {
        final mqtt = MqttService();
        ok = await mqtt.publishMessage(device.id, device.deviceId, 'send:$buttonName');
      }
    } else {
      ok = await _sendHttpCommand(device, 'send:$buttonName', Duration(seconds: 5));
    }

    if (!ok) {
      print("Falha ao enviar comando para o dispositivo ${device.name}");
    }
  }

  /// Envia um [command] genérico ao [device] e retorna true se bem-sucedido.
  ///
  /// Segue a mesma lógica de protocolo que [sendButton].
  Future<bool> sendCommand({
    required String command,
    required Device device,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString("communication_mode") ?? "auto";
    final autoMode = mode == "auto";
    bool ok = false;

    if (autoMode) {
      final currentSsid = await _getCurrentSsid();
      if (currentSsid == device.ssid) {
        ok = await _sendHttpCommand(device, command, Duration(milliseconds: 500));
      }
      if (!ok) {
        final mqtt = MqttService();
        ok = await mqtt.publishMessage(device.id, device.deviceId, command);
      }
    } else {
      ok = await _sendHttpCommand(device, command, Duration(seconds: 5));
    }

    if (!ok) {
      print("Falha ao enviar comando para o dispositivo ${device.name}");
    }

    return ok;
  }
}
