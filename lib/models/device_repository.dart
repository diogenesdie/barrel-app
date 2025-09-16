import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:smart_home/utils/session_utils.dart';
import 'device.dart';
import 'group.dart'; // <-- importar o model Group

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

  Future<void> addDevice(Device device) async {
    await _box.put(device.id, device);
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

  Future<void> removeDevice(String id) async {
    await _box.delete(id);
  }

  Future<void> clearDevices() async {
    await _box.clear();
  }

  Future<void> updateDevice(Device device) async {
    await device.save();
  }

  Future<void> syncDevices() async {
    try {
      final localDevices = getDevices();
      final token = await SessionUtils.getToken();

      final response = await http.post(
        Uri.parse("$apiBaseUrl/devices"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(localDevices.map((d) => d.toJson()).toList()),
      );

      if (response.statusCode == 200) {
        final List<dynamic> remoteDevices = jsonDecode(response.body);
        await clearDevices();
        for (final dev in remoteDevices) {
          await addDevice(Device.fromJson(dev));
        }
      } else {
        throw Exception("Erro ao sincronizar dispositivos: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Erro na sincronização: $e");
    }
  }

  Future<void> syncDevicesGet() async {
    try {
      final token = await SessionUtils.getToken();

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
            await addDevice(Device.fromJson(dev));
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
