import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:smart_home/components/gradient_icon.dart';
import 'package:smart_home/core/constants.dart';
import 'package:smart_home/pages/ble_wifi_setup_page.dart';
import 'package:smart_home/pages/perfil_page.dart';
import 'package:smart_home/pages/search_devices_page.dart';
import 'package:smart_home/pages/your_home_page.dart';
import 'package:smart_home/providers/voice_command_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> devices = [];
  late stt.SpeechToText _speech;
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _loadDevices();

    _pages = [const YourHomePage(), const SearchDevicesPage(), const PerfilPage()];
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 10,
        shadowColor: Colors.grey[200],
        title: Row(children: [
          Icon(Icons.home_outlined),
          SizedBox(width: 10),
          Text('Barrel Smart Home'),
        ],),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).primaryColorLight, Theme.of(context).primaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
      ),
      body: PageView(controller: _pageController, onPageChanged: _onPageChanged, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: GradientIcon(
              icon: Icons.home,
              gradient: LinearGradient(
                colors: [Theme.of(context).primaryColorLight, Theme.of(context).primaryColor],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              isSelected: _selectedIndex == 0,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: GradientIcon(
              icon: Icons.list,
              gradient: LinearGradient(
                colors: [Theme.of(context).primaryColorLight, Theme.of(context).primaryColor],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              isSelected: _selectedIndex == 1,
            ),
            label: 'Dispositivos',
          ),
          BottomNavigationBarItem(
            icon: GradientIcon(
              icon: Icons.person,
              gradient: LinearGradient(
                colors: [Theme.of(context).primaryColorLight, Theme.of(context).primaryColor],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              isSelected: _selectedIndex == 2,
            ),
            label: 'Perfil',
          ),
        ],
        showUnselectedLabels: true,
      ),
    );
  }
}