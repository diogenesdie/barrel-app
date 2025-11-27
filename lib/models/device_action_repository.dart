import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_home/models/device_action.dart';

class DeviceActionRepository {
  static const String _boxName = "deviceActionsBox";
  final String apiBaseUrl;

  DeviceActionRepository({required this.apiBaseUrl});

  static Future<void> initHive() async {
    await Hive.initFlutter();
    Hive.registerAdapter(DeviceActionAdapter());
    await Hive.openBox<DeviceAction>(_boxName);
  }

  Box<DeviceAction> get _box => Hive.box<DeviceAction>(_boxName);

  Future<DeviceAction?> getDeviceById(int id) async {
    return _box.get(id);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
