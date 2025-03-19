import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

const String serviceUuid = "12345678-1234-5678-1234-56789abcdef0";
const String characteristicUuid = "abcdef01-1234-5678-1234-56789abcdef0";

class BLEWifiSetupPage extends StatefulWidget {
  const BLEWifiSetupPage({super.key});

  @override
  BLEWifiSetupPageState createState() => BLEWifiSetupPageState();
}

class BLEWifiSetupPageState extends State<BLEWifiSetupPage> {
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? wifiCharacteristic;

  TextEditingController ssidController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  void startScan() async {
    FlutterBluePlus.startScan(timeout: Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (result.device.name == "BARREL_SETUP_PLUG") {
          FlutterBluePlus.stopScan();
          connectToDevice(result.device);
          break;
        }
      }
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    await device.connect();
    connectedDevice = device;

    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString() == serviceUuid) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == characteristicUuid) {
            wifiCharacteristic = characteristic;
            setState(() {});
            break;
          }
        }
      }
    }
  }

  void sendWifiCredentials() async {
    if (wifiCharacteristic == null) return;

    String ssid = ssidController.text.trim();
    String password = passwordController.text.trim();
    String credentials = "$ssid,$password";

    await wifiCharacteristic!.write(credentials.codeUnits);
    print("Sent: $credentials");

    // Ler resposta do ESP32
    List<int> response = await wifiCharacteristic!.read();
    String responseStr = String.fromCharCodes(response);
    print("ESP32 Response: $responseStr");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("ESP32 Response: $responseStr")),
    );
  }

  @override
  void dispose() {
    connectedDevice?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Connect ESP32 via BLE")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: startScan,
              child: Text("Scan & Connect to ESP32"),
            ),
            SizedBox(height: 20),
            TextField(
              controller: ssidController,
              decoration: InputDecoration(labelText: "WiFi SSID"),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "WiFi Password"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: sendWifiCredentials,
              child: Text("Send WiFi Credentials"),
            ),
          ],
        ),
      ),
    );
  }
}
