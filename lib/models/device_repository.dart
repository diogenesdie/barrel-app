import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import  'device.dart';

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
    return _box.values.toList();
  }

  Future<void> removeDevice(String id) async {
    await _box.delete(id);
  }

  Future<void> clearDevices() async {
    await _box.clear();
  }

  Future<void> syncDevices() async {
    try {
      final localDevices = getDevices();

      final response = await http.post(
        Uri.parse("$apiBaseUrl/devices/sync"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(localDevices.map((d) => d.toJson()).toList()),
      );

      if (response.statusCode == 200) {
        final List<dynamic> remoteDevices = jsonDecode(response.body);
        await clearDevices();
        for (final dev in remoteDevices) {
          await addDevice(Device.fromJson(dev));
        }
      } else {
        throw Exception("Erro ao sincronizar: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Erro na sincronização: $e");
    }
  }
}
