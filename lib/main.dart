import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smart_home/models/device_repository.dart';
import 'package:smart_home/models/group_repository.dart';
import 'package:smart_home/pages/checking_session_page.dart';
import 'package:smart_home/pages/home_page.dart';
import 'package:smart_home/pages/auth_page.dart';

class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      return kDebugMode;
    };
    return client;
  }
}

void main() async {
  if (kDebugMode) {
    HttpOverrides.global = DevHttpOverrides();
  }

  WidgetsFlutterBinding.ensureInitialized();
  await DeviceRepository.initHive();
  await GroupRepository.initHive();

  runApp(const SmartHomeApp());
}

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
