// =============================================================================
// permission_utils.dart
//
// Gerenciamento de permissões do sistema operacional.
// Atualmente cobre apenas BLUETOOTH_SCAN (necessário para descoberta de
// dispositivos via BLE no Android 12+).
// =============================================================================

// Terceiros
import 'package:permission_handler/permission_handler.dart';

/// Verifica e solicita a permissão BLUETOOTH_SCAN (Android 12+).
///
/// - Se concedida: retorna true.
/// - Se negada: solicita ao usuário e retorna o resultado.
/// - Se permanentemente negada: abre as configurações do app e retorna false.
Future<bool> checkBluetoothScanPermission() async {
  // Para Android 12+ é necessário BLUETOOTH_SCAN
  var status = await Permission.bluetoothScan.status;

  if (status.isGranted) {
    return true;
  } else if (status.isDenied) {
    // pede ao usuário
    var result = await Permission.bluetoothScan.request();
    return result.isGranted;
  } else if (status.isPermanentlyDenied) {
    // direciona para configurações
    openAppSettings();
    return false;
  }

  return false;
}
