import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:smart_home/models/device.dart';
import 'package:smart_home/services/mqtt_service.dart';
import 'package:smart_home/utils/crypto_utils.dart';

class ButtonSenderService {
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

  Future<String?> _getCurrentSsid() async {
    final info = NetworkInfo();
    final ssid = await info.getWifiName();
    return ssid?.replaceAll('"', '');
  }
  
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
