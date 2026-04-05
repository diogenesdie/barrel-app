// =============================================================================
// device_repository.dart
//
// Repositório de dispositivos com persistência dual:
//   - Local:  Hive (box "devicesBox") para acesso offline
//   - Remoto: API REST via HTTP para sincronização com o servidor
//
// Também sincroniza dispositivos favoritos com SharedPreferences para
// que o widget de tela inicial (home screen widget) possa acessá-los
// sem depender do Hive.
// =============================================================================

// Dart SDK
import 'dart:convert';

// Terceiros
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Projeto — modelos
import 'package:smart_home/models/device_action.dart';

// Projeto — serviços e utils
import 'package:smart_home/services/mqtt_service.dart';
import 'package:smart_home/utils/session_utils.dart';
import 'package:smart_home/utils/widget_utils.dart';

// Modelos locais (mesmo diretório)
import 'device.dart';
import 'group.dart';

/// Repositório responsável pelo ciclo de vida dos dispositivos.
///
/// Gerencia criação, leitura, atualização e remoção tanto no cache Hive local
/// quanto na API REST remota. Também mantém a lista de favoritos sincronizada
/// no SharedPreferences para uso pelo home screen widget.
class DeviceRepository {
  static const String _boxName = "devicesBox";
  final String apiBaseUrl;

  DeviceRepository({required this.apiBaseUrl});

  /// Inicializa o Hive e abre o box de dispositivos.
  /// Deve ser chamado em [main()] antes de [runApp].
  static Future<void> initHive() async {
    await Hive.initFlutter();
    Hive.registerAdapter(DeviceAdapter());
    await Hive.openBox<Device>(_boxName);
  }

  Box<Device> get _box => Hive.box<Device>(_boxName);

  /// Retorna o dispositivo com o [id] informado, ou null se não encontrado no cache local.
  Future<Device?> getDeviceById(int id) async {
    return _box.get(id);
  }

  /// Salva o dispositivo no cache local. Se [sync] for true, envia para a API REST.
  Future<void> addDevice(Device device, bool sync) async {
    await _box.put(device.id, device);
    if (sync) {
      await syncDevicePostPut(device, true);
    }
    await addOrRemoveToSharedPreferencesWhenFavorite(device);
  }

  /// Retorna todos os dispositivos do cache local, ordenados pela posição do grupo.
  List<Device> getDevices() {
    final devices = _box.values.toList();
    final groupBox = Hive.box<Group>("groupsBox");
    final groups = groupBox.values.toList();

    final groupPositions = {
      for (final g in groups) g.id: g.position,
    };

    devices.sort((a, b) {
      final posA = groupPositions[a.groupId] ?? 9999;
      final posB = groupPositions[b.groupId] ?? 9999;
      return posA.compareTo(posB);
    });

    return devices;
  }

  /// Remove o dispositivo localmente e na API. Também remove suas automações ([DeviceAction]).
  Future<void> removeDevice(int id) async {
    final device = _box.get(id);
    if (device != null && device.isFavorite) {
      device.isFavorite = false;
      await addOrRemoveToSharedPreferencesWhenFavorite(device);
    }

    await syncDeviceDelete(device!.id);

    final actionBox = Hive.box<DeviceAction>("deviceActionsBox");
    final actionsToRemove = actionBox.values.where((a) => a.targetDeviceId == id).toList();

    for (final action in actionsToRemove) {
      await actionBox.delete(action.key);
    }
  }

  Future<void> clearDevices() async {
    await _box.clear();
  }

  /// Mantém a lista de favoritos no SharedPreferences sincronizada com o estado do [device].
  /// Usada pelo home screen widget do sistema operacional, que não acessa o Hive diretamente.
  Future<void> addOrRemoveToSharedPreferencesWhenFavorite(Device device) async {
    final prefs = await SharedPreferences.getInstance();
    final devicesJson = prefs.getString("devices") ?? "[]";
    final List<dynamic> devicesList = jsonDecode(devicesJson);

    final idStr = device.id.toString();
    final index = devicesList.indexWhere((d) => d['id'].toString() == idStr);

    if (device.isFavorite) {
      if (index == -1) {
        devicesList.add(device.toJsonWithId());
      } else {
        devicesList[index] = device.toJsonWithId();
      }
    } else {
      if (index != -1) {
        devicesList.removeAt(index);
      }
    }

    await prefs.setString("devices", jsonEncode(devicesList));

    updateWidget();
  }

  /// Atualiza o dispositivo no cache local e, se [sync] for true, envia para a API REST.
  Future<void> updateDevice(Device device, {bool sync = true}) async {
    await _box.put(device.id, device);
    await addOrRemoveToSharedPreferencesWhenFavorite(device);
    if (sync) {
      await syncDevicePostPut(device, false);
    }
  }

  /// Envia DELETE para a API e remove o dispositivo do cache Hive.
  Future<void> syncDeviceDelete(int id) async {
    try {
      final token = await SessionUtils.getToken();
      if (token == null || token.isEmpty) {
        await _box.delete(id);
        return;
      }

      final response = await http.delete(
        Uri.parse("$apiBaseUrl/devices/$id"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode != 200) {
        throw Exception("Erro ao deletar dispositivo: ${response.statusCode}");
      }

      await _box.delete(id);
    } catch (e) {
      throw Exception("Erro na sincronização: $e");
    }
  }

  /// Envia POST (criação) ou PUT (atualização) para a API e substitui o cache local
  /// pelo dispositivo retornado pelo servidor (pode ter um id diferente após criação).
  /// Também republica as automações MQTT associadas ao dispositivo.
  Future<void> syncDevicePostPut(Device device, bool newDevice) async {
    try {
      final token = await SessionUtils.getToken();
      if (token == null || token.isEmpty) return;

      final url = newDevice ? "$apiBaseUrl/devices" : "$apiBaseUrl/devices/${device.id}";
      final method = newDevice ? 'POST' : 'PUT';

      final deviceJson = device.toJson();
      if (method == 'PUT') {
        deviceJson.remove('device_id');
      }

      final response = await (method == 'POST'
          ? http.post(
              Uri.parse(url),
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $token",
              },
              body: jsonEncode(deviceJson),
            )
          : http.put(
              Uri.parse(url),
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $token",
              },
              body: jsonEncode(deviceJson),
            ));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final decoded = jsonDecode(decodedBody);
        final updatedDevice = Device.fromJson(decoded['data']);
        if (updatedDevice.id != device.id) {
          await _box.delete(device.id);
        }
        await addDevice(updatedDevice, false);

        // Envia action para o ESP32 se houver ações associadas
        if (device.actions != null && device.actions!.isNotEmpty) {
          final mqtt = MqttService();
          for (final action in device.actions!) {
            Device targetDevice = await getDeviceById(action.targetDeviceId) as Device;
            Device triggerDevice = await getDeviceById(action.triggerDeviceId) as Device;

            await mqtt.publishMessage(triggerDevice.id, triggerDevice.deviceId, "action,${action.triggerEvent},${action.actionType},${targetDevice.ip},users/${targetDevice.owner_username}/${targetDevice.deviceId}/command");
          }
        }
      } else {
        throw Exception("Erro ao sincronizar dispositivo: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Erro na sincronização: $e");
    }
  }

  /// Baixa todos os dispositivos da API e substitui o cache local completamente.
  Future<void> syncDevicesGet() async {
    try {
      final token = await SessionUtils.getToken();
      if (token == null || token.isEmpty) return;

      final response = await http.get(
        Uri.parse("$apiBaseUrl/devices"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final decoded = jsonDecode(decodedBody);

        if (decoded is Map<String, dynamic> && decoded['data'] is List) {
          final List<dynamic> remoteDevices = decoded['data'];

          await clearDevices();
          for (final dev in remoteDevices) {
            await addDevice(Device.fromJson(dev), false);
          }
        } else {
          throw Exception("Formato inesperado da resposta da API");
        }
      } else {
        throw Exception("Erro ao buscar dispositivos: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Erro na sincronização: $e");
    }
  }

  /// Remove todos os dispositivos do cache local sem sincronizar com a API.
  Future<void> clearAll() async {
    await _box.clear();
  }
}
