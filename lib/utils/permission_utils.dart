import 'package:permission_handler/permission_handler.dart';

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
