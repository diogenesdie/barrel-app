import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:smart_home/core/constants.dart';
import 'package:smart_home/pages/search_devices_page.dart';
import 'package:smart_home/providers/voice_command_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uni_links/uni_links.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> devices = [];
  late stt.SpeechToText _speech;

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _handleDeepLinks();
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  void _handleDeepLinks() async {
    uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        String command = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : "";
        _processCommand(command);
      }
    });
  }

  void _processCommand(String phrase) {
    print('Comando recebido: $phrase');

    String command = phrase;
    if (phrase.contains('eva')) {
      command = phrase.split('eva').last.trim().toLowerCase();
    }

    // Mapear comandos para ações
    Map<String, List<String>> commandMapping = {
      'ligar': ['on', 'liga', 'acender', 'abre'],
      'desligar': ['off', 'desliga', 'apagar', 'fecha']
    };

    List<dynamic> foundedDevices = [];

    // Procurar dispositivos correspondentes
    for (var device in devices) {
      String deviceName = device['name'].toLowerCase();
      List<String> deviceNameParts = deviceName.split(' ');
      if (deviceNameParts.any((part) => command.contains(part))) {
        foundedDevices.add(device);
      }
    }

    if (foundedDevices.length == 1) {
      var device = foundedDevices.first;
      print('Dispositivo encontrado: ${device['name']}');
      String action = commandMapping.keys.firstWhere(
        (key) => commandMapping[key]!.any((word) => command.contains(word)),
        orElse: () => '',
      );

      if (action.isNotEmpty) {
        final actionObj = device["actions"].firstWhere(
          (a) => a["type"] == "switch",
          orElse: () => null,
        );

        if (actionObj != null) {
          int index = devices.indexOf(device);
          _toggleDevice(
            device["external_port"].toString(),
            actionObj["route"],
            index,
          );
        }
      }
    }
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
      case "light":
        return Icons.lightbulb;
      case "garage":
        return Icons.garage;
      case "fan":
        return Icons.ac_unit;
      case "thermostat":
        return Icons.thermostat;
      default:
        return Icons.device_unknown;
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

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceCommandProvider>(builder: (context, voiceProvider, child) {
      voiceProvider.onCommandExecuted = (command) {
        print("Command executed: $command");
        _processCommand(command);
      };
      return Scaffold(
        appBar: AppBar(
          title: Text(!voiceProvider.isListening ? 'Diga "Eva"' : 'Ouvindo...'),
          centerTitle: voiceProvider.isListening,
          backgroundColor: !voiceProvider.isListening ? Theme.of(context).primaryColor : Colors.red,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: devices.isEmpty
                    ? const Center(child: Text("Nenhum dispositivo encontrado."))
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          bool hasAction = device["actions"] != null && device["actions"].isNotEmpty;

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(_getIcon(device["icon"])),
                                      const SizedBox(width: 4),
                                      Text(device["name"]),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  if (hasAction)
                                    IconButton(
                                      style: ElevatedButton.styleFrom(
                                        iconSize: 48,
                                      ),
                                      icon: const Icon(Icons.power_settings_new),
                                      onPressed: () {
                                        final action = device["actions"].firstWhere((a) => a["type"] == "switch", orElse: () => null);
                                        if (action != null) {
                                          String route = action["route"];
                                          String externalPort = device["external_port"].toString();
                                          _toggleDevice(externalPort, route, index);
                                        }
                                      },
                                    ),
                                  const SizedBox(height: 10),
                                  if (device["props"]["state"] != null)
                                    Container(
                                      padding: const EdgeInsets.only(left: 8, right: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: device["props"]["state"] == "on" ? Colors.green : Colors.red,
                                      ),
                                      child: Text(
                                        device["props"]["state"] == "on" ? "Ligado" : "Desligado",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.manage_search),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchDevicesPage(),
                      ),
                    ).then((_) => _loadDevices());
                  },
                  label: const Text("Gerenciar dispositivos"),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
