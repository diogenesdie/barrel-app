import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:smart_home/components/gradient_icon.dart';
import 'package:smart_home/core/constants.dart';
import 'package:smart_home/pages/devices_page.dart';
import 'package:smart_home/pages/perfil_page.dart';
import 'package:smart_home/pages/your_home_page.dart';
import 'package:smart_home/utils/session_utils.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> devices = [];
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  late final List<Widget> _pages;

  bool _autoProtocol = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _loadCommMode();

    _pages = [const YourHomePage(), const DevicesPage(), const PerfilPage()];
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final devicesJson = prefs.getString("devices") ?? "[]";
    getDevicesStates(jsonDecode(devicesJson));
  }

  Future<void> _loadCommMode() async {
    bool isLoggedIn = await SessionUtils.isLoggedIn();

    if (!isLoggedIn) {
      setState(() {
        _autoProtocol = false;
      });
      _saveCommMode(false);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getBool(COMM_KEY);
    if (savedMode != null) {
      setState(() {
        _autoProtocol = savedMode;
      });
    }
  }

  Future<void> _saveCommMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(COMM_KEY, value);
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

  void _toggleCommunicationMode() async {
    bool isLoggedIn = await SessionUtils.isLoggedIn();

    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orangeAccent,
          content: Text("Você precisa estar logado para usar a comunicação Online."),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _autoProtocol = !_autoProtocol;
    });

    await _saveCommMode(_autoProtocol);

    final mode = _autoProtocol ? "Automático (Local/Online)" : "Comunicação Local";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Modo alterado para: $mode"),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 10,
        shadowColor: Colors.grey[200],
        title: Row(
          children: [
            Icon(Icons.home_outlined),
            SizedBox(width: 10),
            Text('Barrel Smart Home'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Alterar modo de comunicação",
            onPressed: _toggleCommunicationMode,
            icon: Icon(
              _autoProtocol ? Icons.wifi : Icons.home_filled,
            ),
          ),
        ],
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
            label: 'Ínicio',
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
