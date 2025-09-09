import 'dart:convert';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:smart_home/components/device_warning.dart';
import 'package:smart_home/components/dialogs/device_config_dialog.dart';
import 'package:smart_home/components/no_device.dart';
import 'package:smart_home/core/constants.dart';
import 'package:smart_home/services/mqtt_service.dart';
import 'package:smart_home/utils/devices_utils.dart';
import 'package:smart_home/utils/permission_utils.dart';
import 'package:smart_home/utils/session_utils.dart';
import 'dart:async';

import 'package:smart_home/utils/weather_utils.dart';
import 'package:network_info_plus/network_info_plus.dart';

const String serviceUuid = "12345678-1234-5678-1234-56789abcdef0";
const String wifiCharacteristicUuid = "abcdef01-1234-5678-1234-56789abcdef0";
const String deviceIdCharUuid = "abcdef02-1234-5678-1234-56789abcdef0";

class YourHomePage extends StatefulWidget {
  const YourHomePage({super.key});

  @override
  State<YourHomePage> createState() => _YourHomePageState();
}

class _YourHomePageState extends State<YourHomePage> with WidgetsBindingObserver {
  List<dynamic> devices = [];
  IWeather? weather;
  final List<Map<String, dynamic>> esps = [];
  bool isScanning = false;
  bool isAdding = false;
  bool isConnecting = false;
  bool isLoadingDevices = false;
  bool isBluetoothEnabled = true;
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? wifiCharacteristic;
  String? _wifiSSID;
  String? _wifiError;
  late TextEditingController ssidController;
  late TextEditingController passwordController;
  late TextEditingController accessKeyController;
  Map<String, dynamic>? _configuringEsp;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadWeather();
    _loadDevices();
    ssidController = TextEditingController();
    passwordController = TextEditingController();
    accessKeyController = TextEditingController();
    _getWifiSSID();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _getWifiSSID();
    }
  }

  Future<void> _getWifiSSID() async {
    try {
      var status = await Permission.locationWhenInUse.status;
      if (!status.isGranted) {
        status = await Permission.locationWhenInUse.request();
      }

      if (status.isGranted) {
        final info = NetworkInfo();
        final ssid = await info.getWifiName();
        setState(() {
          _wifiSSID = ssid?.replaceAll('"', '');
          ssidController.text = _wifiSSID ?? "";
          _wifiError = (ssid == null || ssid.isEmpty) ? "Você não está conectado no Wi-Fi" : null;
        });
      } else {
        setState(() {
          _wifiError = "Estamos sem permissão para listar seu Wi-Fi";
        });
      }
    } catch (e) {
      setState(() {
        _wifiSSID = null;
        _wifiError = "Ocorreu um erro ao buscar sua rede Wi-Fi: $e";
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

  Future<List<Map<String, dynamic>>> _discoverDevicesReturn() async {
    var state = await FlutterBluePlus.adapterState.first;
    var isOn = state == BluetoothAdapterState.on;
    setState(() {
      isBluetoothEnabled = isOn;
    });
    if (!isOn) {
      return [];
    }

    try {
      await checkBluetoothScanPermission();
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    } on PlatformException catch (e) {
      print("Erro de plataforma: ${e.message}");
      return [];
    } catch (e) {
      print("Erro inesperado: $e");
      return [];
    }
    List<Map<String, dynamic>> foundDevices = [];

    // Aguarda o término da varredura
    await Future.delayed(Duration(seconds: 5));

    // Obtém os resultados da varredura
    print(FlutterBluePlus.scanResults.first);
    List<ScanResult> results = await FlutterBluePlus.scanResults.first;

    for (ScanResult result in results) {
      print(result.device.platformName);
      if (result.device.platformName.contains("BARREL")) {
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
    setState(() {
      isLoadingDevices = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final devicesJson = prefs.getString("devices") ?? "[]";

    getDevicesStates(jsonDecode(devicesJson));

    setState(() {
      isLoadingDevices = false;
    });
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

  Future<String?> discoverDeviceIp() async {
    final client = MDnsClient();
    await client.start();
    final ptr = await client
        .lookup<IPAddressResourceRecord>(
          ResourceRecordQuery.addressIPv4('barrel.local'),
        )
        .first;
    client.stop();
    return ptr.address.address;
  }

  Future<void> connectToDevice(BluetoothDevice device, String credentials) async {
    await device.connect();
    connectedDevice = device;

    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString() == serviceUuid) {
        for (var characteristic in service.characteristics) {
          final uuid = characteristic.uuid.toString().toLowerCase();

          if (uuid == wifiCharacteristicUuid) {
            wifiCharacteristic = characteristic;
            sendWifiCredentials(credentials);
            setState(() {});
          }

          if (uuid == deviceIdCharUuid.toLowerCase()) {
            List<int> value = await characteristic.read();
            String deviceId = String.fromCharCodes(value);
            print("Device ID: $deviceId");
          }
        }
      }
    }
  }

  void sendWifiCredentials(String credentials) async {
    if (wifiCharacteristic == null) return;

    await wifiCharacteristic!.write(credentials.codeUnits);

    List<int> response = await wifiCharacteristic!.read();
    String responseStr = String.fromCharCodes(response);

    startDeviceConfig(context);
  }

  void startDeviceConfig(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // não fecha clicando fora
      builder: (context) {
        return DeviceConfigDialog(
          steps: [
            "Conectando ao dispositivo…",
            "Configurando a conexão Wi-Fi…",
            "Obtendo informações do dispositivo…",
            "Configuração concluída!",
          ],
          onProcess: (updateStep) async {
            // Simulação do processo com delays
            await Future.delayed(const Duration(seconds: 2));
            updateStep("Enviando credenciais Wi-Fi…");

            await Future.delayed(const Duration(seconds: 2));
            updateStep("Obtendo IP do dispositivo…");

            await Future.delayed(const Duration(seconds: 2));
            updateStep("Configuração concluída!");
          },
        );
      },
    );
  }

  Future<void> testMqttService() async {
    final mqtt = MqttService();

    final username = await SessionUtils.getUsername();
    final password = await SessionUtils.getPassword();

    // conecta
    await mqtt.connect(
      clientId: "flutter_test_${DateTime.now().millisecondsSinceEpoch}",
      username: username ?? "testUser",
      password: password ?? "testPass",
    );

    // publica mensagem de teste
    final ok = await mqtt.publishMessage("device123", "Hello MQTT 🚀");

    if (ok) {
      print("✅ Mensagem publicada com sucesso!");
    } else {
      print("❌ Falha ao publicar a mensagem");
    }

    // desconecta depois de 5s
    await Future.delayed(const Duration(seconds: 5));
    mqtt.disconnect();
  }

  void onAddDevice() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        bool obscurePassword = true;
        bool obscureAccessKey = true;

        final PageController pageController = PageController();

        void onItemTapped(int index) {
          pageController.animateToPage(
            index,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
          );
        }

        return StatefulBuilder(builder: (context, setModalState) {
          return AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SizedBox(
              height: 450,
              child: PageView(
                controller: pageController,
                children: [
                  FutureBuilder<List>(
                    future: _discoverDevicesReturn(),
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
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: !isBluetoothEnabled
                                  ? deviceWarning("Bluetooth desativado", "Ative o Bluetooth para procurar dispositivos", Icons.bluetooth_disabled)
                                  : esps.isEmpty
                                      ? deviceWarning("Nenhum dispositivo encontrado", "Tente aproximar o dispositivo do celular e verifique se ele está ligado", Icons.phonelink_off)
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
                                                  setState(() {
                                                    _configuringEsp = esp;
                                                    onItemTapped(1);
                                                  });
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
                    child: _wifiError != null && _wifiError!.isNotEmpty
                        ? deviceWarning("Wi-Fi desativado", "Ative o Wi-Fi para configurar o dispositivo", Icons.wifi_off, onTap: () {
                            AppSettings.openAppSettings(type: AppSettingsType.wifi);
                          })
                        : Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        onItemTapped(0);
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
                                decoration: const InputDecoration(labelText: "SSID (Nome da Rede Wi-Fi conectada)"),
                                readOnly: true,
                                style: TextStyle(color: Colors.grey[700]),
                                onTap: () {
                                  AppSettings.openAppSettings(type: AppSettingsType.wifi);
                                },
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: passwordController,
                                obscureText: obscurePassword,
                                decoration: InputDecoration(
                                  labelText: "Senha do Wi-Fi",
                                  suffix: GestureDetector(
                                    onTap: () => setModalState(() {
                                      obscurePassword = !obscurePassword;
                                    }),
                                    child: Icon(
                                      obscurePassword ? Icons.visibility : Icons.visibility_off,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: accessKeyController,
                                obscureText: obscureAccessKey,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                decoration: InputDecoration(
                                  labelText: "Chave de Acesso (6 dígitos)",
                                  suffix: GestureDetector(
                                    onTap: () => setModalState(() {
                                      obscureAccessKey = !obscureAccessKey;
                                    }),
                                    child: Icon(
                                      obscureAccessKey ? Icons.visibility : Icons.visibility_off,
                                    ),
                                  ),
                                ),
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
                                  onPressed: () async {
                                    final ssid = ssidController.text;
                                    final password = passwordController.text;
                                    final username = await SessionUtils.getUsername();
                                    final userPass = await SessionUtils.getPassword();

                                    final credentials = "$ssid,$password,$username,$userPass";
                                    if (_configuringEsp != null) {
                                      await connectToDevice(_configuringEsp!["device"], credentials);
                                    }
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
        });
      },
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
                          FutureBuilder<String>(
                            future: getMessage(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Text("Carregando...", style: TextStyle(fontSize: 16, color: Colors.white));
                              } else if (snapshot.hasError) {
                                return Text("Erro: ${snapshot.error}", style: const TextStyle(fontSize: 16, color: Colors.red));
                              } else {
                                return Text(snapshot.data ?? "", style: const TextStyle(fontSize: 16, color: Colors.white));
                              }
                            },
                          ),
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
                    onPressed: isAdding || isScanning
                        ? null
                        : () {
                            onAddDevice();
                          },
                    icon: Icon(Icons.add, color: Theme.of(context).primaryColorLight),
                    iconSize: 15,
                    alignment: Alignment.center,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            isLoadingDevices
                ? const Center(child: CircularProgressIndicator())
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: devices.isEmpty
                        ? [
                            noDevice(onTap: () {
                              onAddDevice();
                            })
                          ]
                        : devices.map((device) {
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
