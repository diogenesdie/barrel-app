// =============================================================================
// device_action_repository.dart
//
// Repositório de automações de dispositivos.
//
// ATENÇÃO: Implementação incompleta — contém apenas inicialização e clearAll().
// Os métodos de sincronização com a API (POST/PUT/DELETE/GET) ainda precisam
// ser implementados. As automações são salvas como parte do [Device.actions]
// via [DeviceRepository] por enquanto.
// =============================================================================

import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_home/models/device_action.dart';

/// Repositório de automações ([DeviceAction]).
///
/// Atualmente possui implementação mínima; a lógica de sincronização com
/// a API REST ainda não foi implementada.
class DeviceActionRepository {
  static const String _boxName = "deviceActionsBox";
  final String apiBaseUrl;

  DeviceActionRepository({required this.apiBaseUrl});

  /// Inicializa o Hive e abre o box de automações.
  /// Deve ser chamado em [main()] antes de [runApp].
  static Future<void> initHive() async {
    await Hive.initFlutter();
    Hive.registerAdapter(DeviceActionAdapter());
    await Hive.openBox<DeviceAction>(_boxName);
  }

  Box<DeviceAction> get _box => Hive.box<DeviceAction>(_boxName);

  /// Retorna a automação com a chave [id] no box Hive.
  /// Nota: o nome 'getDeviceById' é um equívoco histórico — este método retorna um [DeviceAction].
  Future<DeviceAction?> getDeviceById(int id) async {
    return _box.get(id);
  }

  /// Remove todas as automações do cache local.
  Future<void> clearAll() async {
    await _box.clear();
  }
}
