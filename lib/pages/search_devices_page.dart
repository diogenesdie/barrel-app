import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:smart_home/core/constants.dart';
import 'package:smart_home/utils/devices_utils.dart';

class SearchDevicesPage extends StatefulWidget {
  const SearchDevicesPage({super.key});

  @override
  SearchDevicesPageState createState() => SearchDevicesPageState();
}

class SearchDevicesPageState extends State<SearchDevicesPage> {
  final List<Map<String, String>> esps = [];
  bool isScanning = false;
  bool isAdding = false;
  List<BluetoothDevice> devices = [];

  @override
  void initState() {
    super.initState();
    // discoverDevices();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> discoverDevicesMDNS() async {
    setState(() {
      isScanning = true;
    });

    final MDnsClient client = MDnsClient();
    await client.start();

    try {
      await for (PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer('_http._tcp.local'),
      )) {
        await for (SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName),
        )) {
          String ipAddress = "Desconhecido";
          String friendlyName = "Desconhecido";
          bool isAdded = false;

          await for (IPAddressResourceRecord ip in client.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(srv.target),
          )) {
            ipAddress = ip.address.address;
          }

          await for (TxtResourceRecord txt in client.lookup<TxtResourceRecord>(
            ResourceRecordQuery.text(ptr.domainName),
          )) {
            for (var entry in txt.text.split("\n")) {
              if (entry.startsWith("name=")) {
                friendlyName = entry.substring(5);
              }
            }
          }

          final deviceInfo = {"name": friendlyName, "ip": ipAddress, "port": srv.port.toString(), "isAdded": isAdded.toString()};

          print(deviceInfo);
        }
      }
    } catch (e) {
      print("Erro ao buscar dispositivos: $e");
    } finally {
      client.stop();
      setState(() {
        isScanning = false;
      });
    }
  }

  String _getType(String ssid) {
    if (ssid.contains("PLUG")) {
      return "plug";
    } else if (ssid.contains("LIGHT")) {
      return "light";
    } else if (ssid.contains("SWITCH")) {
      return "switch";
    } else if (ssid.contains("TRIGGER")) {
      return "trigger";
    } else if (ssid.contains("RF")) {
      return "rf";
    }

    return "unknown";
  }

  String _getName(String ssid) {
    if (ssid.contains("PLUG")) {
      return "Smart Plug";
    } else if (ssid.contains("LIGHT")) {
      return "Smart Light";
    } else if (ssid.contains("SWITCH")) {
      return "Smart Switch";
    } else if (ssid.contains("TRIGGER")) {
      return "Smart Trigger";
    } else if (ssid.contains("RF")) {
      return "Smart RF Controller";
    }

    return "Unknown";
  }

  void discoverDevices() async {
    FlutterBluePlus.startScan(timeout: Duration(seconds: 5));
    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        esps.clear();
        isScanning = true;
      });

      for (ScanResult result in results) {
        if (result.device.platformName.contains("BARREL")) {
          final type = _getType(result.device.platformName);
          final name = _getName(result.device.platformName);
          final ip = result.device.remoteId.toString();
          final port = result.advertisementData.txPowerLevel.toString();
          final isAdded = false;

          final deviceInfo = {"type": type, "name": name, "ip": ip, "port": port, "isAdded": isAdded.toString()};

          if (!esps.any((d) => d["ip"] == ip)) {
            setState(() {
              esps.add(deviceInfo);
            });
          }
        }
      }

      setState(() {
        isScanning = false;
      });
    });
  }

  void showMessage(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void onConnectEsp(Map<String, String> esp) async {
    setState(() {
      isAdding = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final espList = prefs.getStringList("esp") ?? [];

    if (espList.contains(esp["ip"])) {
      showMessage("Ops", "Este dispositivo já está cadastrado.");
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("http://${esp["ip"]}:8080/devices"),
        headers: {
          "Authorization": "Bearer $BEARER_TOKEN",
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData["devices"] is List<dynamic>) {
          final devices = jsonData["devices"] as List;

          if (devices.isEmpty) {
            showMessage("Erro", "Nenhum dispositivo encontrado.");
            return;
          }

          final prefs = await SharedPreferences.getInstance();

          espList.add(esp["ip"]!);
          await prefs.setStringList("esp", espList);

          final currentDevices = prefs.getString("devices") ?? "[]";
          final currentDevicesList = jsonDecode(currentDevices) as List;

          for (var device in devices) {
            device["ip"] = esp["ip"];
            device["external_port"] = jsonData["external_port"];
          }

          final newDevices = [...currentDevicesList, ...devices];

          await prefs.setString("devices", jsonEncode(newDevices));

          showMessage("Sucesso", "Dispositivos adicionados com sucesso.");
        } else {
          showMessage("Erro", "Falha ao conectar com o dispositivo.");
        }
      } else {
        showMessage("Erro", "Falha ao conectar com o dispositivo.");
      }
    } catch (e) {
      showMessage("Erro", "Falha ao conectar com o dispositivo.");
    }

    setState(() {
      isAdding = false;
    });

    discoverDevices();
  }

  void onDisconnectEsp(Map<String, String> esp) async {
    setState(() {
      isAdding = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final espList = prefs.getStringList("esp") ?? [];

    if (!espList.contains(esp["ip"])) {
      showMessage("Ops", "Este dispositivo não está cadastrado.");
      return;
    }

    espList.remove(esp["ip"]!);
    await prefs.setStringList("esp", espList);

    final currentDevices = prefs.getString("devices") ?? "[]";
    final currentDevicesList = jsonDecode(currentDevices) as List;

    final newDevices = currentDevicesList.where((d) => d["ip"] != esp["ip"]).toList();
    await prefs.setString("devices", jsonEncode(newDevices));

    showMessage("Sucesso", "Dispositivos removidos com sucesso.");

    setState(() {
      isAdding = false;
    });

    discoverDevices();
  }

  void deleteAllData() async {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Atenção"),
            content: Text("Tem certeza que deseja apagar todos os dados?"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("Cancelar"),
              ),
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();

                  discoverDevices();

                  Navigator.pop(context);
                },
                child: Text("Apagar"),
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gerenciar Dispositivos"),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: deleteAllData,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: esps.length,
              itemBuilder: (context, index) {
                final esp = esps[index];
                return ListTile(
                  enabled: !isScanning && !isAdding,
                  leading: Icon(Icons.devices),
                  title: Text(esp["name"] ?? "Desconhecido"),
                  subtitle: Text("IP: ${esp["ip"]}, Porta: ${esp["port"]}"),
                  trailing: Opacity(
                    opacity: isScanning || isAdding ? 0.5 : 1,
                    child: ElevatedButton.icon(
                      icon: esp["isAdded"] == "true" ? Icon(Icons.link_off) : Icon(Icons.connect_without_contact_rounded),
                      onPressed: () {
                        if (esp["isAdded"] == "true") {
                          onDisconnectEsp(esp);
                        } else {
                          onConnectEsp(esp);
                        }
                      },
                      label: esp["isAdded"] == "true" ? Text("Desconectar") : Text("Conectar"),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: isScanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.search),
              onPressed: isScanning ? null : discoverDevices,
              label: Text(isScanning ? "Procurando..." : "Buscar Dispositivos"),
            ),
          ),
        ],
      ),
    );
  }
}
