// =============================================================================
// home_page.dart
//
// Hub de navegação principal do aplicativo.
//
// Estrutura de abas (PageView + BottomNavigationBar):
//   - Índice 0: YourHomePage  — dashboard de controle de dispositivos
//   - Índice 1: DevicesPage   — gerenciamento de dispositivos e grupos
//   - Índice 2: PerfilPage    — perfil do usuário e configurações
//
// Também gerencia o toggle de modo de comunicação (auto/local) no AppBar,
// persistido em SharedPreferences via [COMM_KEY].
// =============================================================================

// Dart SDK
import 'dart:async';
import 'dart:convert';

// Flutter
import 'package:flutter/material.dart';

// Terceiros
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Projeto — componentes e core
import 'package:smart_home/components/gradient_icon.dart';
import 'package:smart_home/core/constants.dart';

// Projeto — páginas
import 'package:smart_home/pages/devices_page.dart';
import 'package:smart_home/pages/perfil_page.dart';
import 'package:smart_home/pages/your_home_page.dart';

// Projeto — utils
import 'package:smart_home/utils/session_utils.dart';

/// Tela principal com navegação por abas (Início, Dispositivos, Perfil).
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // SECTION: Estado — dispositivos e navegação
  List<dynamic> devices = [];
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  late final List<Widget> _pages;
  late bool _isLoggedIn;

  bool _autoProtocol = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _loadCommMode();
    SessionUtils.isLoggedIn().then((value) {
      setState(() {
        _isLoggedIn = value;
      });
    });

    _pages = [const YourHomePage(), const DevicesPage(), const PerfilPage()];
  }

  // SECTION: Carregamento de dados

  /// Carrega os dispositivos favoritos do SharedPreferences e busca seus estados HTTP.
  Future<void> _loadDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final devicesJson = prefs.getString("devices") ?? "[]";
    getDevicesStates(jsonDecode(devicesJson));
  }

  /// Lê o modo de comunicação salvo no SharedPreferences e atualiza o estado.
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
    } else {
      setState(() {
        _autoProtocol = true;
      });
      _saveCommMode(true);
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
          headers: {"Authorization": "Bearer $BEARER_TOKEN"},
        );
        if (response.statusCode == 200) {
          final deviceState = jsonDecode(response.body);
          device["props"]["state"] = deviceState["state"];
        }
      } catch (e) {
        print('Erro ao obter o estado do dispositivo: $e');
      }
    }

    setState(() {
      devices = devicesParam;
    });
  }

  // SECTION: Ações do usuário

  /// Navega para a aba [index] com animação suave.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Alterna o modo de comunicação entre auto (nuvem) e local, persistindo a preferência.
  void _toggleCommunicationMode() async {
    bool isLoggedIn = await SessionUtils.isLoggedIn();

    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orangeAccent,
          content: Text("Você precisa estar logado para usar a comunicação Online."),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _autoProtocol = !_autoProtocol;
    });

    await _saveCommMode(_autoProtocol);
    final icon = _autoProtocol ? Icons.cloud : Icons.router;
    final title = _autoProtocol ? "Modo Online" : "Modo Local";
    final subtitle = _autoProtocol ? "Conecta via internet quando fora de casa" : "Conecta direto pelo Wi-Fi";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
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
          children: const [
            Icon(Icons.home_outlined),
            SizedBox(width: 10),
            Text('Barrel Smart Home'),
          ],
        ),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              tooltip: "Alterar modo de comunicação",
              onPressed: _toggleCommunicationMode,
              icon: Icon(_autoProtocol ? Icons.cloud : Icons.router),
            ),
          if (_selectedIndex == 1 && _isLoggedIn)
            IconButton(
              tooltip: "Gerenciar compartilhamentos",
              onPressed: () {
                Navigator.of(context).pushNamed('/manage_shares');
              },
              icon: const Icon(FontAwesomeIcons.shareNodes),
            ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).primaryColorLight, Theme.of(context).primaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _pages,
      ),
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
