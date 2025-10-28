import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_home/utils/session_utils.dart';
import 'package:smart_home/utils/widget_utils.dart';
import 'device.dart';
import 'group.dart';

class DeviceRepository {
  static const String _boxName = "devicesBox";
  final String apiBaseUrl;

  DeviceRepository({required this.apiBaseUrl});

  static Future<void> initHive() async {
    await Hive.initFlutter();
    Hive.registerAdapter(DeviceAdapter());
    await Hive.openBox<Device>(_boxName);
  }

  Box<Device> get _box => Hive.box<Device>(_boxName);

  Future<void> addDevice(Device device, bool sync) async {
    await _box.put(device.id, device);
    if (sync) {
      await syncDevicePostPut(device, true);
    }
    await addOrRemoveToSharedPreferencesWhenFavorite(device);
  }

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

  Future<void> removeDevice(int id) async {
    final device = _box.get(id);
    if (device != null && device.isFavorite) {
      device.isFavorite = false;
      await addOrRemoveToSharedPreferencesWhenFavorite(device);
    }

    await syncDeviceDelete(id);
  }

  Future<void> clearDevices() async {
    await _box.clear();
  }

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

  Future<void> updateDevice(Device device, {bool sync = true}) async {
    await _box.put(device.id, device);
    await addOrRemoveToSharedPreferencesWhenFavorite(device);
    if (sync) {
      await syncDevicePostPut(device, false);
    }
  }

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

  Future<void> syncDevicePostPut(Device device, bool newDevice) async {
    try {
      final token = await SessionUtils.getToken();
      if (token == null || token.isEmpty) return;

      final url = newDevice ? "$apiBaseUrl/devices" : "$apiBaseUrl/devices/${device.id}";
      final method = newDevice ? 'POST' : 'PUT';

      print("Enviando dispositivo: ${device.toJson()}");

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
        final decoded = jsonDecode(response.body);
        final updatedDevice = Device.fromJson(decoded['data']);
        if (updatedDevice.id != device.id) {
          await _box.delete(device.id);
        }
        await addDevice(updatedDevice, false);
      } else {
        throw Exception("Erro ao sincronizar dispositivo: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Erro na sincronização: $e");
    }
  }

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
        final decoded = jsonDecode(response.body);

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
}
