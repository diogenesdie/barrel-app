// =============================================================================
// device_button_repository.dart
//
// Repositório de botões de controle remoto (IR/RF).
// Persistência somente local via Hive (box "deviceButtonsBox").
//
// A busca dos botões disponíveis é feita diretamente no firmware do
// dispositivo via HTTP (porta 8080), não na API REST do servidor.
// =============================================================================

// Dart SDK
import 'dart:convert';

// Terceiros
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

// Projeto — modelos
import 'package:smart_home/models/device_button.dart';

/// Repositório de botões de controle remoto de dispositivos IR/RF.
///
/// Gerencia o cache local Hive e a busca direta do firmware do dispositivo.
class DeviceButtonRepository {
  static const String _boxName = "deviceButtonsBox";

  DeviceButtonRepository();

  static Future<void> initHive() async {
    Hive.registerAdapter(DeviceButtonAdapter());
    await Hive.openBox<DeviceButton>(_boxName);
  }

  Box<DeviceButton> get _box => Hive.box<DeviceButton>(_boxName);

  /// Retorna todos os botões do cache local associados ao [deviceId].
  Future<List<DeviceButton>> getButtonsForDevice(int deviceId) async {
    return _box.values.where((b) => b.deviceId == deviceId).toList();
  }

  /// Salva a lista de [buttons] no cache local, associando-os ao [deviceId].
  Future<void> saveButtons(List<DeviceButton> buttons, int deviceId) async {
    for (var b in buttons) {
      b.deviceId = deviceId;
      await _box.put("${b.deviceId}_${b.id}", b);
    }
  }

  /// Busca os botões disponíveis diretamente do firmware do dispositivo via HTTP.
  /// Se [saveAfterFetch] for true, salva os botões no cache Hive após a busca.
  Future<List<DeviceButton>> fetchFromDevice(String ip, int deviceId, bool saveAfterFetch) async {
    final response = await http.get(Uri.parse("http://$ip:8080/buttons")).timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) {
      throw Exception("Erro ao buscar botões do dispositivo");
    }

    final data = jsonDecode(response.body);

    List<DeviceButton> buttons = (data["buttons"] as List)
        .map((json) => DeviceButton.fromJson(json, deviceId))
        .toList();

    if (saveAfterFetch) {
      await saveButtons(buttons, deviceId);
    }

    return buttons;
  }

  /// Remove todos os botões do [deviceId] do cache local.
  Future<void> deleteAllFromDevice(int deviceId) async {
    final keysToDelete = _box.keys.where((key) {
      final b = _box.get(key);
      return b != null && b.deviceId == deviceId;
    }).toList();

    for (var key in keysToDelete) {
      await _box.delete(key);
    }
  }

  Future<void> insertButton(DeviceButton button) async {
    await _box.put("${button.deviceId}_${button.id}", button);
  }

  Future<void> deleteButton(int buttonId) async {
    final keyToDelete = _box.keys.firstWhere(
      (key) {
        final b = _box.get(key);
        return b != null && b.id == buttonId;
      },
      orElse: () => null,
    );

    if (keyToDelete != null) {
      await _box.delete(keyToDelete);
    }
  }
}
