import 'package:flutter/material.dart';
import 'package:smart_home/pages/home_page.dart';

void main() {
  runApp(SmartHomeApp());
}

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
      theme: ThemeData(
        primarySwatch: Colors.brown,
        primaryColor: Colors.brown,
        primaryColorLight: Colors.brown[200],
        dialogBackgroundColor: Colors.grey[200],
        drawerTheme: DrawerThemeData(
          backgroundColor: Colors.white,
          elevation: 5,
          shadowColor: const Color.fromARGB(255, 238, 238, 238),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.brown,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
          iconTheme: IconThemeData(color: Colors.white),
          actionsIconTheme: IconThemeData(color: Colors.white),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
              const EdgeInsets.all(8),
            ),
            //putple background color with white icon coplor
            backgroundColor: MaterialStateProperty.all<Color>(Colors.brown),
            foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
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
        floatingActionButtonTheme: FloatingActionButtonThemeData(
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
        useMaterial3: true,
      ),
    );
  }
}
