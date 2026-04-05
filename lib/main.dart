// =============================================================================
// main.dart
//
// Ponto de entrada do aplicativo Barrel Smart Home.
//
// Responsabilidades:
//   - Ignora certificados SSL inválidos em modo debug (DevHttpOverrides)
//   - Inicializa os boxes Hive antes de runApp()
//   - Define o tema global da aplicação (Material 3, cores marrons)
//   - Configura as rotas nomeadas do aplicativo
// =============================================================================

// Dart SDK
import 'dart:io';

// Flutter
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Projeto — modelos
import 'package:smart_home/models/device_action_repository.dart';
import 'package:smart_home/models/device_button_repository.dart';
import 'package:smart_home/models/device_repository.dart';
import 'package:smart_home/models/group_repository.dart';

// Projeto — páginas
import 'package:smart_home/pages/auth_page.dart';
import 'package:smart_home/pages/checking_session_page.dart';
import 'package:smart_home/pages/home_page.dart';
import 'package:smart_home/pages/manage_shares_page.dart';

/// Sobrescreve o cliente HTTP para aceitar certificados inválidos em [kDebugMode].
///
/// Necessário para desenvolvimento local com servidores que usam certificados
/// autoassinados. Nunca habilitado em builds de produção.
class DevHttpOverrides extends HttpOverrides {
  @override

  /// Permite qualquer certificado quando o app está rodando em modo de desenvolvimento.
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      return kDebugMode;
    };
    return client;
  }
}

/// Inicializa o Hive, registra adapters e inicia o aplicativo.
void main() async {
  if (kDebugMode) {
    HttpOverrides.global = DevHttpOverrides();
  }

  WidgetsFlutterBinding.ensureInitialized();
  await DeviceActionRepository.initHive();
  await DeviceButtonRepository.initHive();
  await DeviceRepository.initHive();
  await GroupRepository.initHive();

  runApp(const SmartHomeApp());
}

/// Widget raiz do aplicativo. Define tema global e rotas nomeadas.
class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (_) => const CheckingSessionPage(),
        '/auth': (_) => const AuthPage(),
        '/home': (_) => const HomePage(),
        '/manage_shares': (_) => const ManageShares(),
      },
      theme: ThemeData(
        // Corrige o roxo dos botões no Material 3
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown,
          brightness: Brightness.light,
        ),
        useMaterial3: true,

        primarySwatch: Colors.brown,
        primaryColor: Colors.brown,
        primaryColorLight: const Color(0xFFB8860B),

        dialogBackgroundColor: Colors.grey[200],
        drawerTheme: const DrawerThemeData(
          backgroundColor: Colors.white,
          elevation: 5,
          shadowColor: Color.fromARGB(255, 238, 238, 238),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.brown,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
          iconTheme: IconThemeData(color: Colors.white),
          actionsIconTheme: IconThemeData(color: Colors.white),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFFB8860B),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.brown,
          unselectedItemColor: Colors.grey[800],
        ),
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
              const EdgeInsets.all(8),
            ),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFB8860B)),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          errorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
          ),
          labelStyle: TextStyle(color: Colors.grey[400]),
        ),
        listTileTheme: ListTileThemeData(
          tileColor: Colors.white,
          leadingAndTrailingTextStyle: const TextStyle(color: Colors.black),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.brown,
          selectionColor: Colors.brown[100],
          selectionHandleColor: Colors.brown,
        ),
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18, color: Colors.black),
          bodySmall: TextStyle(fontSize: 14, color: Colors.black),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black),
        ),
        cardTheme: CardTheme(
          elevation: 5,
          color: Colors.brown[50],
          shadowColor: const Color.fromARGB(100, 238, 238, 238),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.brown),
            foregroundColor: MaterialStateProperty.all(Colors.white),
            iconColor: MaterialStateProperty.all(Colors.white),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.brown;
            }
            return Colors.grey;
          }),
          trackColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.brown[100];
            }
            return Colors.grey[300];
          }),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
        ),
        // NOTA: Estilo alternativo para InputDecorationTheme com bordas arredondadas.
        //       Mantido para referência; o estilo ativo usa UnderlineInputBorder acima.
        // inputDecorationTheme: InputDecorationTheme(
        //   filled: true,
        //   fillColor: Colors.white,
        //   contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        //   labelStyle: TextStyle(
        //     color: Colors.brown.shade700,
        //     fontWeight: FontWeight.w500,
        //   ),
        //   floatingLabelStyle: TextStyle(
        //     color: Theme.of(context).primaryColor,
        //     fontWeight: FontWeight.w600,
        //   ),
        //   border: OutlineInputBorder(
        //     borderRadius: BorderRadius.circular(12),
        //     borderSide: BorderSide(color: Colors.brown.shade200),
        //   ),
        //   enabledBorder: OutlineInputBorder(
        //     borderRadius: BorderRadius.circular(12),
        //     borderSide: BorderSide(color: Colors.brown.shade200, width: 1),
        //   ),
        //   focusedBorder: OutlineInputBorder(
        //     borderRadius: BorderRadius.circular(12),
        //     borderSide: BorderSide(
        //       color: Theme.of(context).primaryColor,
        //       width: 1.6,
        //     ),
        //   ),
        // ),
        dropdownMenuTheme: DropdownMenuThemeData(
          menuStyle: MenuStyle(
            backgroundColor: const WidgetStatePropertyAll(Colors.white),
            surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
            shadowColor: const WidgetStatePropertyAll(Colors.black26),
            elevation: const WidgetStatePropertyAll(4),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          textStyle: TextStyle(
            color: Colors.grey.shade900,
            fontWeight: FontWeight.w500,
          ),
        ),
        tabBarTheme: TabBarTheme(
          labelColor: Colors.brown,
          unselectedLabelColor: Colors.grey[800],
          indicator: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.brown, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}
