import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:smart_home/core/constants.dart';
import 'package:smart_home/utils/devices_utils.dart';
import 'dart:async';

import 'package:smart_home/utils/weather_utils.dart';
import 'package:network_info_plus/network_info_plus.dart';

const String serviceUuid = "12345678-1234-5678-1234-56789abcdef0";
const String characteristicUuid = "abcdef01-1234-5678-1234-56789abcdef0";

class YourHomePage extends StatefulWidget {
  const YourHomePage({super.key});

  @override
  State<YourHomePage> createState() => _YourHomePageState();
}

class _YourHomePageState extends State<YourHomePage> {
  List<dynamic> devices = [];
  IWeather? weather;
  final List<Map<String, dynamic>> esps = [];
  bool isScanning = false;
  bool isAdding = false;
  bool isConnecting = false;
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? wifiCharacteristic;
  String? _wifiSSID;
  String? _wfiiError;

  @override
  void initState() {
    super.initState();
    _loadWeather();
    _loadDevices();
    // _discoverDevicesWait();
  }

  void _discoverDevicesWait() async {
    final devices = await _discoverDevicesReturn();
    setState(() {
      esps.clear();
      esps.addAll(devices);
    });
  }

  Future<void> _getWifiSSID() async {
    try {
      // Android precisa de localização para ler SSID/BSSID
      var status = await Permission.locationWhenInUse.status;
      if (!status.isGranted) {
        status = await Permission.locationWhenInUse.request();
      }

      if (status.isGranted) {
        final info = NetworkInfo();
        final ssid = await info.getWifiName(); // SSID pode vir com aspas em alguns devices
        setState(() {
          _wifiSSID = ssid;
          _wfiiError = (ssid == null || ssid.isEmpty) ? "Você não está conectado no Wi-Fi" : null;
        });
      } else {
        setState(() {
          _wfiiError = "Estamos sem permissão para listar seu Wi-Fi";
        });
      }
    } catch (e) {
      setState(() {
        _wifiSSID = null;
        _wfiiError = "Ocorreu um erro ao buscar sua rede Wi-Fi: $e";
      });
    }
  }

  void _loadWeather() async {
    Map<String, double>? coords = await getCoords();

    if (coords == null) {
      return;
    }

    var currentHour = DateTime.now().hour;
    var weatherTemp = await getWeather(coords['latitude']!, coords['longitude']!, currentHour);
    setState(() {
      weather = weatherTemp;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _discoverDevices() async {
    FlutterBluePlus.startScan(timeout: Duration(seconds: 5));
    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        esps.clear();
        isScanning = true;
      });

      for (ScanResult result in results) {
        if (result.device.platformName.contains("BARREL_SETUP")) {
          final type = getDeviceType(result.device.platformName);
          final name = getDeviceName(result.device.platformName);
          final ip = result.device.remoteId.toString();
          final port = result.advertisementData.txPowerLevel.toString();
          final isAdded = false;

          final deviceInfo = {"type": type, "name": name, "ip": ip, "port": port, "isAdded": isAdded.toString(), "device": result.device};

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

  Future<List<Map<String, dynamic>>> _discoverDevicesReturn() async {
    List<Map<String, dynamic>> foundDevices = [];

    // Inicia a varredura
    FlutterBluePlus.startScan(timeout: Duration(seconds: 5));

    // Aguarda o término da varredura
    await Future.delayed(Duration(seconds: 5));

    // Obtém os resultados da varredura
    List<ScanResult> results = await FlutterBluePlus.scanResults.first;

    for (ScanResult result in results) {
      if (result.device.platformName.contains("BARREL_SETUP")) {
        final type = getDeviceType(result.device.platformName);
        final name = getDeviceName(result.device.platformName);
        final ip = result.device.remoteId.toString();
        final port = result.advertisementData.txPowerLevel.toString();
        final isAdded = false;

        final deviceInfo = {"type": type, "name": name, "ip": ip, "port": port, "isAdded": isAdded.toString(), "device": result.device};

        if (!foundDevices.any((d) => d["ip"] == ip)) {
          foundDevices.add(deviceInfo);
        }
      }
    }

    return foundDevices;
  }

  Future<void> _loadDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final devicesJson = prefs.getString("devices") ?? "[]";

    getDevicesStates(jsonDecode(devicesJson));
  }

  void getDevicesStates(List<dynamic> devicesParam) async {
    for (final device in devicesParam) {
      final url = 'http://$PUBLIC_IP:${device["external_port"]}${device["routes"]["state"]}';

      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {
            "Authorization": "Bearer $BEARER_TOKEN",
          },
        );

        if (response.statusCode == 200) {
          final deviceState = jsonDecode(response.body);
          device["props"]["state"] = deviceState["state"];
        } else {
          print('Falha ao obter o estado do dispositivo: ${response.statusCode}');
        }
      } catch (e) {
        print('Erro ao obter o estado do dispositivo: $e');
      }
    }

    setState(() {
      devices = devicesParam;
    });
  }

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case "lightbulb":
      case "light":
        return FontAwesomeIcons.lightbulb;
      case "garage":
        return FontAwesomeIcons.car;
      case "fan":
        return FontAwesomeIcons.fan;
      case "thermostat":
        return FontAwesomeIcons.temperatureHalf;
      default:
        return FontAwesomeIcons.question;
    }
  }

  List<Color> _getButtonColor(String state) {
    if (state == "on") {
      return [Theme.of(context).primaryColorLight, Theme.of(context).primaryColor];
    } else {
      return [Colors.grey, Colors.grey];
    }
  }

  Future<void> _toggleDevice(String externalPort, String route, int index) async {
    final url = 'http://$PUBLIC_IP:$externalPort$route';
    setState(() {
      devices[index]["props"]["state"] = devices[index]["props"]["state"] == "on" ? "off" : "on";
    });
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $BEARER_TOKEN",
        },
      );
      if (response.statusCode == 200) {
        _loadDevices();
      } else {
        print('Falha ao acionar o dispositivo: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao acionar o dispositivo: $e');
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
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

    final ssid = _wifiSSID ?? '';
    final password = ''; // preencha a partir do seu controller
    final credentials = "$ssid,$password";

    await wifiCharacteristic!.write(credentials.codeUnits);
    final response = await wifiCharacteristic!.read();
    final responseStr = String.fromCharCodes(response);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("ESP32 Response: $responseStr")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Card(
              elevation: 10,
              shadowColor: Colors.grey[200],
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: getGradient(),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(getMessage(), style: const TextStyle(fontSize: 16, color: Colors.white)),
                          const Spacer(),
                          Icon(Icons.location_on_outlined, color: Colors.white),
                          Text(
                            weather == null ? "" : weather!.city,
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                      weather == null
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  "assets/${weather?.icon}.svg",
                                  width: 100,
                                  semanticsLabel: 'Weather Icon',
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      "${weather!.temperature.toInt()}°C",
                                      style: const TextStyle(fontSize: 45, color: Colors.white, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      "${weather!.temperatureMin.toInt()}°C - ${weather!.temperatureMax.toInt()}°C",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 28),
                              ],
                            ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Text(
                    "Dispositivos",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  IconButton.outlined(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      side: BorderSide(width: 2, color: Theme.of(context).primaryColorLight),
                    ),
                    onPressed: () async {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true, // Permite que o modal suba com o teclado
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (context) {
                          final PageController _pageController = PageController();
                          TextEditingController ssidController = TextEditingController();
                          TextEditingController passwordController = TextEditingController();
                          TextEditingController accessKeyController = TextEditingController();

                          void _onItemTapped(int index) {
                            _pageController.animateToPage(
                              index,
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOutCubic,
                            );
                          }

                          return AnimatedPadding(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                            child: SizedBox(
                              height: 400,
                              child: PageView(
                                controller: _pageController,
                                children: [
                                  FutureBuilder<List>(
                                    future: _discoverDevicesReturn(), // Chama a função que retorna a lista de dispositivos
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(child: CircularProgressIndicator());
                                      }
                                      if (snapshot.hasError) {
                                        return Center(child: Text("Erro ao buscar dispositivos"));
                                      }
                                      final esps = snapshot.data ?? [];

                                      return Container(
                                        padding: const EdgeInsets.all(16.0),
                                        width: double.infinity,
                                        child: Column(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.search, color: Theme.of(context).primaryColorLight),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    "Dispositivos encontrados",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.grey[800],
                                                    ),
                                                  ),
                                                  IconButton(
                                                      onPressed: () {
                                                        _onItemTapped(2);
                                                      },
                                                      icon: Icon(Icons.chevron_right))
                                                ],
                                              ),
                                            ),
                                            const Divider(),
                                            Expanded(
                                              child: esps.isEmpty
                                                  ? const Center(child: Text("Nenhum dispositivo encontrado"))
                                                  : ListView.builder(
                                                      itemCount: esps.length,
                                                      itemBuilder: (context, index) {
                                                        final esp = esps[index];
                                                        return ListTile(
                                                          leading: Container(
                                                            width: 40,
                                                            height: 40,
                                                            decoration: BoxDecoration(
                                                              shape: BoxShape.circle,
                                                              color: Theme.of(context).primaryColorLight,
                                                            ),
                                                            child: getDeviceIcon(esp["type"] ?? "unknown"),
                                                          ),
                                                          title: Text(esp["name"] ?? "Desconhecido"),
                                                          subtitle: Text(getDeviceSubtitle(esp["type"] ?? "unknown")),
                                                          trailing: ElevatedButton.icon(
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: Theme.of(context).primaryColorLight,
                                                            ),
                                                            icon: esp["isAdded"] == "true" ? const FaIcon(FontAwesomeIcons.linkSlash) : const FaIcon(FontAwesomeIcons.link),
                                                            onPressed: () async {
                                                              if (esp["isAdded"] == "true") {
                                                                // onDisconnectEsp(esp);
                                                              } else {
                                                                await connectToDevice(esp["device"]);
                                                                esp["device"].disconnect();
                                                              }
                                                            },
                                                            label: Text(esp["isAdded"] == "true" ? "Desconectar" : "Conectar"),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(16.0),
                                    height: 600,
                                    width: double.infinity,
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                          child: Row(
                                            children: [
                                              IconButton(
                                                onPressed: () {
                                                  _onItemTapped(2);
                                                },
                                                icon: Icon(Icons.chevron_left),
                                              ),
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Theme.of(context).primaryColorLight,
                                                ),
                                                child: getDeviceIcon("plug"),
                                              ),
                                              const SizedBox(width: 8),
                                              Column(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Barrel Plug",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.grey[800],
                                                    ),
                                                  ),
                                                  Text(
                                                    "Tomada inteligente",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Divider(),
                                        TextField(
                                          controller: ssidController,
                                          decoration: const InputDecoration(labelText: "SSID (Nome da Rede Wi-Fi)"),
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                          controller: passwordController,
                                          obscureText: true,
                                          decoration: const InputDecoration(labelText: "Senha do Wi-Fi"),
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                          controller: accessKeyController,
                                          obscureText: true,
                                          keyboardType: TextInputType.number,
                                          maxLength: 6,
                                          decoration: const InputDecoration(labelText: "Chave de Acesso (6 dígitos)"),
                                        ),
                                        const SizedBox(height: 24),
                                        Container(
                                          width: double.infinity,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: _getButtonColor("on"),
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            label: const Text("Configurar"),
                                            icon: const FaIcon(FontAwesomeIcons.gear),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    icon: Icon(Icons.add, color: Theme.of(context).primaryColorLight),
                    iconSize: 15,
                    alignment: Alignment.center,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            devices.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: devices.map((device) {
                      bool hasAction = device["actions"] != null && device["actions"].isNotEmpty;

                      return SizedBox(
                        width: MediaQuery.of(context).size.width / 2 - 24, // Ajusta para 2 colunas
                        child: Card(
                          elevation: 10,
                          shadowColor: Colors.grey[200],
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.rectangle,
                                        color: Theme.of(context).primaryColorLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(_getIcon(device["icon"]), color: Colors.white, size: 12),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(device["name"], overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (hasAction)
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: _getButtonColor(device["props"]["state"]),
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      iconSize: 80,
                                      color: Colors.transparent,
                                      style: ButtonStyle(
                                        backgroundColor: MaterialStateProperty.all(Colors.transparent),
                                      ),
                                      icon: const Icon(Icons.power_settings_new, color: Colors.white),
                                      onPressed: () {
                                        final action = device["actions"].firstWhere(
                                          (a) => a["type"] == "switch",
                                          orElse: () => null,
                                        );
                                        if (action != null) {
                                          String route = action["route"];
                                          String externalPort = device["external_port"].toString();
                                          _toggleDevice(externalPort, route, devices.indexOf(device));
                                        }
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )
          ],
        ),
      ),
    );
  }
}
