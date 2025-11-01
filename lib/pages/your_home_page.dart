import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_home/components/device_warning.dart';
import 'package:smart_home/components/dialogs/device_config_dialog.dart';
import 'package:smart_home/components/dialogs/error_message_dialog.dart';
import 'package:smart_home/components/loading.dart';
import 'package:smart_home/components/no_device.dart';
import 'package:smart_home/components/sequencial_text_switch.dart';
import 'package:smart_home/core/constants.dart';
import 'package:smart_home/models/device.dart';
import 'package:smart_home/models/device_repository.dart';
import 'package:smart_home/models/group.dart';
import 'package:smart_home/models/group_repository.dart';
import 'package:smart_home/services/mqtt_service.dart';
import 'package:smart_home/utils/devices_utils.dart';
import 'package:smart_home/utils/permission_utils.dart';
import 'package:smart_home/utils/session_utils.dart';
import 'dart:async';

import 'package:smart_home/utils/weather_utils.dart';
import 'package:network_info_plus/network_info_plus.dart';

const String serviceUuid = "12345678-1234-5678-1234-56789abcdef0";
const String wifiCharacteristicUuid = "abcdef01-1234-5678-1234-56789abcdef0";

class AnimatedGradientButton extends StatelessWidget {
  final bool stateOn;
  final IconData icon;

  const AnimatedGradientButton({
    super.key,
    required this.stateOn,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = stateOn ? [Theme.of(context).primaryColorLight, Theme.of(context).primaryColor] : [Colors.grey[600]!, Colors.grey[800]!];

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(begin: colors.first, end: colors.first),
      duration: const Duration(milliseconds: 500),
      builder: (context, color1, _) {
        return TweenAnimationBuilder<Color?>(
          tween: ColorTween(begin: colors.last, end: colors.last),
          duration: const Duration(milliseconds: 500),
          builder: (context, color2, _) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [color1 ?? colors.first, color2 ?? colors.last],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 64),
            );
          },
        );
      },
    );
  }
}

class YourHomePage extends StatefulWidget {
  const YourHomePage({super.key});

  @override
  State<YourHomePage> createState() => _YourHomePageState();
}

class _YourHomePageState extends State<YourHomePage> with WidgetsBindingObserver {
  List<Device> devices = [];
  List<Group> groups = [];
  IWeather? weather;
  final List<Map<String, dynamic>> esps = [];
  bool isScanning = false;
  bool isAdding = false;
  bool isConnecting = false;
  bool isLoadingDevices = false;
  bool isLoadingGroups = false;
  bool isBluetoothEnabled = true;
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? wifiCharacteristic;
  String? _wifiSSID;
  String? _wifiError;
  late TextEditingController ssidController;
  late TextEditingController passwordController;
  late TextEditingController accessKeyController;
  Map<String, dynamic>? _configuringEsp;
  Future<List<Map<String, dynamic>>>? _scanFuture;
  late DeviceRepository _deviceRepo;
  late GroupRepository _groupRepo;
  void Function(void Function())? _modalSetState;
  late Group defaultGroup;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _requestBluetoothPermissions();

    _loadWeather();
    ssidController = TextEditingController();
    passwordController = TextEditingController();
    accessKeyController = TextEditingController();
    _getWifiSSID();
    _deviceRepo = DeviceRepository(apiBaseUrl: BASE_API_URL);
    _groupRepo = GroupRepository(apiBaseUrl: BASE_API_URL);
    _loadDevices();
    _loadGroups();
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
      _loadDevices();
      _updateBluetoothStatus();
    }
  }

  Future<void> _requestBluetoothPermissions() async {
    final scanStatus = await Permission.bluetoothScan.request();
    final connectStatus = await Permission.bluetoothConnect.request();
    final locStatus = await Permission.locationWhenInUse.request();

    if (scanStatus.isDenied || connectStatus.isDenied || locStatus.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Permissões de Bluetooth/Wi-Fi são necessárias para adicionar dispositivos"),
          ),
        );
      }
    }
  }

  Future<void> _updateBluetoothStatus() async {
    var state = await FlutterBluePlus.adapterState.first;
    bool isOn = state == BluetoothAdapterState.on;

    if (_modalSetState != null) {
      _modalSetState!(() {
        isBluetoothEnabled = isOn;
      });
    }

    if (mounted) {
      setState(() {
        isBluetoothEnabled = isOn;
      });
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

  void _startScan({void Function(void Function())? setModalState}) {
    if (isScanning) return;

    void updateState(Function fn) {
      if (setModalState != null) {
        setModalState(() => fn());
      }
      setState(() => fn());
    }

    updateState(() {
      _scanFuture = _discoverDevicesReturn(setModalState: setModalState);
    });
  }

  Future<List<Map<String, dynamic>>> _discoverDevicesReturn({void Function(void Function())? setModalState}) async {
    print("🔍 Iniciando escaneamento Bluetooth...");
    var state = await FlutterBluePlus.adapterState.first;
    var isOn = state == BluetoothAdapterState.on;
    void updateState(Function fn) {
      if (setModalState != null) {
        setModalState(() => fn());
      }
      setState(() => fn());
    }

    updateState(() {
      isBluetoothEnabled = isOn;
    });
    updateState(() {
      isScanning = true;
    });

    if (!isOn) {
      updateState(() {
        isScanning = false;
      });
      return [];
    }

    try {
      await checkBluetoothScanPermission();
      await FlutterBluePlus.stopScan();
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    } on PlatformException catch (e) {
      print("Erro de plataforma: ${e.message}");
      updateState(() {
        isScanning = false;
      });
      return [];
    } catch (e) {
      print("Erro inesperado: $e");
      updateState(() {
        isScanning = false;
      });
      return [];
    }
    List<Map<String, dynamic>> foundDevices = [];

    // Aguarda o término da varredura
    await Future.delayed(Duration(seconds: 5));

    // Obtém os resultados da varredura
    List<ScanResult> results = await FlutterBluePlus.scanResults.first;

    for (ScanResult result in results) {
      if (result.device.platformName.contains("BARREL")) {
        final type = getDeviceType(result.device.platformName);
        final name = getDeviceName(result.device.platformName);
        final ip = result.device.remoteId.toString();
        final port = result.advertisementData.txPowerLevel.toString();
        final isAdded = false;

        final deviceInfo = {"id": result.device.platformName, "type": type, "name": name, "ip": ip, "port": port, "isAdded": isAdded.toString(), "device": result.device};

        if (!foundDevices.any((d) => d["ip"] == ip)) {
          foundDevices.add(deviceInfo);
        }
      }
    }

    updateState(() {
      isScanning = false;
    });

    return foundDevices;
  }

  Future<void> _loadGroups() async {
    setState(() => isLoadingGroups = true);

    try {
      final loadedGroups = _groupRepo.getGroups();
      setState(() {
        groups = loadedGroups;
        defaultGroup = groups.firstWhere((g) => g.isDefault == true);
      });
    } catch (e) {
      print("Erro ao carregar grupos: $e");
    } finally {
      setState(() => isLoadingGroups = false);
    }
  }

  Future<void> _loadDevices() async {
    setState(() => isLoadingDevices = true);
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final loadedDevices = _deviceRepo.getDevices();
      setState(() {
        devices = loadedDevices;
      });

      final mqtt = MqttService();

      await mqtt.connect(
        clientId: "mobile_${DateTime.now().millisecondsSinceEpoch}",
      );

      for (var d in loadedDevices) {
        mqtt.subscribe(d.id, d.deviceId);
      }

      mqtt.listen((topic, payload) async {
        final parts = payload.split(',');
        if (parts.length == 2) {
          final newState = parts[0];
          final newIp = parts[1];
          final deviceId = topic.split('/').elementAt(2);
          setState(() {
            devices = devices.map((dev) {
              if (dev.deviceId == deviceId) {
                return dev.copyWith(
                  state: newState,
                  ip: newIp,
                );
              }
              return dev;
            }).toList();
          });

          final updatedDevice = devices.firstWhere((d) => d.deviceId == deviceId);
          await _deviceRepo.updateDevice(updatedDevice, sync: false);
        }
      });
    } catch (e) {
      print("Erro ao carregar devices: $e");
    } finally {
      setState(() => isLoadingDevices = false);
    }
  }

  List<Color> _getButtonColor(String state) {
    if (state == "on") {
      return [Theme.of(context).primaryColorLight, Theme.of(context).primaryColor];
    } else {
      return [Colors.grey, Colors.grey];
    }
  }

  Widget _statusDevice(Device device) {
    if (device.type == "trigger") {
      return SequentialTextSwitcher(text: device.state.toUpperCase() == "ON" ? "Disparado" : "Clique para disparar");
    } else if (device.type == "rf") {
      return SequentialTextSwitcher(text: device.state.toUpperCase() == "ON" ? "Enviando Sinal" : "Clique para enviar sinal");
    } else {
      return SequentialTextSwitcher(
        text: device.state.toUpperCase() == "ON" ? "Ligado" : "Desligado",
      );
    }
  }

  Future<bool> _sendHttpCommand(Device device, String newState, Duration timeout) async {
    bool ok = false;
    try {
      final uri = Uri.parse('http://${device.ip}:8080/command');
      final response = await http.post(
        uri,
        body: {'state': newState},
      ).timeout(const Duration(seconds: 5));
      ok = response.statusCode == 200;
      print("Resposta HTTP: ${response.statusCode} - ${response.body}");
    } catch (e) {
      ok = false;
      print("Erro ao enviar comando HTTP local: $e");
    }

    return ok;
  }

  Future<String?> _getCurrentSsid() async {
    final info = NetworkInfo();
    final ssid = await info.getWifiName();
    return ssid?.replaceAll('"', '');
  }

  Future<void> _toggleDevice(Device device) async {
    final prefs = await SharedPreferences.getInstance();
    final autoMode = (prefs.getBool(COMM_KEY) ?? true) || device.type == "trigger";

    String newState = device.state == "on" ? "off" : "on";

    if (device.type == "trigger") {
      if (newState == "on") {
        newState = "trigger";
      } else {
        return;
      }
    } else if (device.type == "rf") {
      newState = "pulse";
    }

    bool ok = false;

    if (autoMode) {
      final currentSsid = await _getCurrentSsid();
      if ("" == currentSsid) {
        ok = await _sendHttpCommand(device, newState, Duration(milliseconds: 500));
      }
      if (!ok) {
        final mqtt = MqttService();
        ok = await mqtt.publishMessage(device.id, device.deviceId, newState);
      }
    } else {
      // MODO LOCAL → HTTP
      ok = await _sendHttpCommand(device, newState, Duration(seconds: 5));
    }

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Falha ao enviar comando"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      if (device.type == 'trigger') {
        setState(() {
          devices = devices.map((d) {
            if (d.id == device.id) {
              return d.copyWith(state: 'on');
            }
            return d;
          }).toList();
        });
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          devices = devices.map((d) {
            if (d.id == device.id) {
              return d.copyWith(state: 'off');
            }
            return d;
          }).toList();
        });
      }
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

  Future<void> startDeviceConfig(BuildContext context, BluetoothDevice device, String deviceId, String credentials) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return DeviceConfigDialog(
          steps: [
            "Conectando ao dispositivo…",
            "Configurando a conexão Wi-Fi…",
            "Obtendo informações do dispositivo…",
            "Configuração concluída!",
          ],
          onProcess: (updateStep) async {
            try {
              // Etapa 1: conectar
              updateStep("Conectando ao dispositivo…");
              try {
                await device.connect(timeout: Duration(seconds: 10));
              } catch (_) {
                try {
                  print("Tentando reconectar...");
                  await Future.delayed(Duration(seconds: 2));
                  await device.connect(timeout: Duration(seconds: 10));
                } catch (e) {
                  print("Tentando reconectar novamente...");
                  await Future.delayed(Duration(seconds: 5));
                  await device.connect(timeout: Duration(seconds: 10));
                }
              }
              connectedDevice = device;
              await Future.delayed(const Duration(milliseconds: 5000));

              // Descobrir serviços
              final services = await device.discoverServices();
              for (var service in services) {
                if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
                  for (var characteristic in service.characteristics) {
                    final uuid = characteristic.uuid.toString().toLowerCase();

                    if (uuid == wifiCharacteristicUuid.toLowerCase()) {
                      wifiCharacteristic = characteristic;
                    }
                  }
                }
              }

              try {
                // Etapa 2: mandar credenciais
                updateStep("Configurando a conexão Wi-Fi…");
                if (wifiCharacteristic != null) {
                  await wifiCharacteristic!.write(credentials.codeUnits);
                  await Future.delayed(const Duration(milliseconds: 300));
                  final resp = await wifiCharacteristic!.read();
                  print("Resposta: ${String.fromCharCodes(resp)}");
                }
              } catch (e) {
                print("Erro ao enviar credenciais: $e");
              }

              // Etapa 3: obter IP (discoverDeviceIp)
              await device.disconnect();
              updateStep("Obtendo informações do dispositivo…");
              await Future.delayed(const Duration(seconds: 5));
              final ip = await discoverDeviceIp();
              print("Dispositivo IP: $ip");
              if (ip == null) {
                throw "Não foi possível obter o IP do dispositivo. Verifique se ele está conectado ao Wi-Fi.";
              }

              String chave_iv = "";
              // só pega a chave iv se for diferente de trigger
              if (!deviceId.toLowerCase().contains("trigger")) {
                // faz chamada para ip dispositivo para registrar /get_key_iv
                final url = 'http://$ip:8080/get_key_iv';
                final response = await http.get(Uri.parse(url));
                if (response.statusCode != 200) {
                  throw "Falha ao registrar o dispositivo: ${response.statusCode}";
                }
                chave_iv = response.body;
                print("Chave e IV: $chave_iv");
              }

              //generate random id integer
              final newDevice = Device(
                id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
                deviceId: deviceId,
                name: getDeviceName(deviceId),
                type: getDeviceType(deviceId),
                icon: getDefaultIconNameByType(getDeviceType(deviceId)),
                ip: ip,
                ivKey: chave_iv,
                state: "off",
                ssid: _wifiSSID ?? "",
                communicationMode: "auto",
                groupId: defaultGroup.id,
              );
              await _deviceRepo.addDevice(newDevice, true);

              // Etapa final
              updateStep("Configuração concluída!");
              await Future.delayed(const Duration(seconds: 2));

              //fecha dialog e atualiza lista
              Navigator.of(context).pop(true);
              Navigator.of(context).pop(true);
              _loadDevices();
            } catch (e) {
              print("Erro no processo de configuração: $e");
              Navigator.of(context).pop(); // fecha dialog

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const FriendlyErrorDialog(
                  message: "Ocorreu um erro durante o processo de configuração, por favor, tente novamente.",
                ),
              );
            }
          },
        );
      },
    );
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

        final PageController pageController = PageController();

        void onItemTapped(int index) {
          if (index < 0 || index >= 2) return;

          if (index == 1 && _configuringEsp == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Selecione um dispositivo para configurar"),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          pageController.animateToPage(
            index,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
          );
        }

        return StatefulBuilder(builder: (context, setModalState) {
          if (_scanFuture == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _startScan(setModalState: setModalState);
            });
          }

          _modalSetState = setModalState;

          return AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SizedBox(
              height: 450,
              child: PageView(
                controller: pageController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  FutureBuilder<List>(
                    future: _scanFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting || isScanning) {
                        return const Center(child: Loading(mensagem: "Buscando dispositivos"));
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
                              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColorLight.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 3,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.devices_other_rounded,
                                      color: Theme.of(context).primaryColorLight,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Dispositivos encontrados",
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[800],
                                            fontSize: 16,
                                          ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      style: IconButton.styleFrom(
                                        backgroundColor: Theme.of(context).primaryColorLight.withOpacity(0.1),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () {
                                        _startScan(setModalState: setModalState);
                                      },
                                      icon: Icon(Icons.refresh_rounded, color: Theme.of(context).primaryColorLight, size: 20),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                                child: !isBluetoothEnabled
                                    ? deviceWarning("Bluetooth desativado", "Ative o Bluetooth para procurar dispositivos", Icons.bluetooth_disabled, onTap: () {
                                        AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
                                      })
                                    : esps.isEmpty
                                        ? deviceWarning("Nenhum dispositivo encontrado", "Tente aproximar o dispositivo do celular e verifique se ele está ligado", Icons.phonelink_off)
                                        : ListView.builder(
                                            padding: const EdgeInsets.all(8),
                                            itemCount: esps.length,
                                            itemBuilder: (context, index) {
                                              final esp = esps[index];
                                              final isAdded = esp["isAdded"] == "true";
                                              final type = esp["type"] ?? "unknown";
                                              final name = esp["name"] ?? "Desconhecido";

                                              return InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    setModalState(() {
                                                      _configuringEsp = esp;
                                                      onItemTapped(1);
                                                    });
                                                  });
                                                },
                                                borderRadius: BorderRadius.circular(20),
                                                child: Container(
                                                  margin: const EdgeInsets.only(bottom: 14),
                                                  padding: const EdgeInsets.all(16),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).primaryColorLight.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(20),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.04),
                                                        blurRadius: 6,
                                                        offset: const Offset(2, 4),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 56,
                                                        height: 56,
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          color: LinearGradient(colors: _getButtonColor("on"), begin: Alignment.topLeft, end: Alignment.bottomRight).colors.first,
                                                        ),
                                                        child: Center(
                                                          child: getDeviceIcon(type),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),

                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              name,
                                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                                    fontWeight: FontWeight.w600,
                                                                  ),
                                                            ),
                                                            const SizedBox(height: 4),
                                                            Text(
                                                              getDeviceSubtitle(type),
                                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                                    color: Colors.grey[600],
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),

                                                      // Status + seta
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.end,
                                                        children: [
                                                          Text(
                                                            isAdded ? "Conectado" : "Disponível",
                                                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                                  color: isAdded ? Theme.of(context).colorScheme.primary : Colors.grey[600],
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                          ),
                                                          const SizedBox(height: 8),
                                                          const Icon(Icons.chevron_right, color: Colors.grey, size: 22),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          )),
                          ],
                        ),
                      );
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    height: 600,
                    width: double.infinity,
                    child: _wifiError != null && _wifiError!.isNotEmpty
                        ? deviceWarning(
                            "Wi-Fi desativado",
                            "Ative o Wi-Fi para configurar o dispositivo",
                            Icons.wifi_off,
                            onTap: () {
                              AppSettings.openAppSettings(type: AppSettingsType.wifi);
                            },
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ----- Cabeçalho -----
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      onItemTapped(0);
                                    },
                                    icon: const Icon(Icons.chevron_left),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.grey.withOpacity(0.1),
                                      shape: const CircleBorder(),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Theme.of(context).primaryColorLight,
                                    ),
                                    child: Center(
                                      child: getDeviceIcon(
                                        _configuringEsp?["type"] ?? "unknown",
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _configuringEsp?["name"] ?? "Dispositivo",
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          getDeviceSubtitle(_configuringEsp?["type"] ?? "unknown"),
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              const Divider(),
                              const SizedBox(height: 12),

                              // ----- Campos -----
                              TextField(
                                controller: ssidController,
                                readOnly: true,
                                onTap: () {
                                  AppSettings.openAppSettings(type: AppSettingsType.wifi);
                                },
                                decoration: InputDecoration(
                                  labelText: "SSID (Nome da Rede Wi-Fi)",
                                  prefixIcon: const Icon(Icons.wifi),
                                ),
                              ),
                              const SizedBox(height: 16),

                              TextField(
                                controller: passwordController,
                                obscureText: obscurePassword,
                                decoration: InputDecoration(
                                  labelText: "Senha do Wi-Fi",
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscurePassword ? Icons.visibility : Icons.visibility_off,
                                    ),
                                    onPressed: () => setModalState(() {
                                      obscurePassword = !obscurePassword;
                                    }),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // ----- Botão Configurar -----
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
                                      await startDeviceConfig(context, _configuringEsp!["device"], _configuringEsp!["id"], credentials);
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
                  ),
                ],
              ),
            ),
          );
        });
      },
    ).whenComplete(() {
      _modalSetState = null;
      setState(() {
        isAdding = false;
        _scanFuture = null;
        _configuringEsp = null;
      });
    });
  }

  Widget _buildDeviceCard(Device device) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[200]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  device.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _getButtonColor(device.state)[1].withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 0,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                        onTap: () {
                          _toggleDevice(device);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedGradientButton(
                          stateOn: device.state == 'on',
                          icon: getDeviceIcon(device, returnData: true),
                        )),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: _statusDevice(device),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Card(
                elevation: 2,
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
                                  return const Loading(color: Colors.white);
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
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColorLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.devices_other_rounded,
                        color: Theme.of(context).primaryColorLight,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Dispositivos",
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                              fontSize: 16,
                            ),
                      ),
                      const Spacer(),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColorLight.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          if (!isAdding) {
                            onAddDevice();
                          }
                        },
                        icon: Icon(Icons.add_rounded, color: Theme.of(context).primaryColorLight, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              isLoadingDevices
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Loading(mensagem: "Carregando dispositivos")),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        if (devices.isEmpty) {
                          return SizedBox(
                            width: double.infinity,
                            child: noDevice(
                              onTap: () {
                                onAddDevice();
                              },
                            ),
                          );
                        }
                        final grouped = <Group, List<Device>>{};
                        for (final g in groups) {
                          grouped[g] = devices.where((d) => d.groupId == g.id).toList();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: grouped.entries.map((entry) {
                            final group = entry.key;
                            final groupDevices = entry.value;

                            if (groupDevices.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColorLight.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            getGroupIconData(group.icon),
                                            color: Theme.of(context).primaryColorLight,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          group.name,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // --- Grade de devices ---
                                  if (groupDevices.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: deviceWarning(
                                        "Nenhum dispositivo neste grupo",
                                        "Adicione ou mova dispositivos para este grupo",
                                        FontAwesomeIcons.boxOpen,
                                      ),
                                    )
                                  else
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: 0.85,
                                      ),
                                      itemCount: groupDevices.length,
                                      itemBuilder: (context, index) {
                                        final device = groupDevices[index];
                                        return _buildDeviceCard(device); // 🔹 usa o mesmo card que já tinha
                                      },
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
