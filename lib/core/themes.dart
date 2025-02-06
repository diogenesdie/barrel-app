import 'package:flutter/material.dart';

ThemeData mainTheme = ThemeData(
  primarySwatch: Colors.brown,
  primaryColor: const Color(0xFF6A1B9A),
  primaryColorLight: const Color(0xFFBA68C8),
  dialogBackgroundColor: Colors.grey[200],
  drawerTheme: DrawerThemeData(
    backgroundColor: Colors.white,
    elevation: 5,
    shadowColor: const Color.fromARGB(255, 238, 238, 238),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: const Color(0xFF6A1B9A),
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
      backgroundColor: MaterialStateProperty.all<Color>(const Color(0xFF6A1B9A)),
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
    cursorColor: const Color(0xFF6A1B9A),
    selectionColor: const Color(0xFFBA68C8),
    selectionHandleColor: const Color(0xFF6A1B9A),
  ),
  scaffoldBackgroundColor: Colors.white,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(fontSize: 18, color: Colors.black),
    bodySmall: TextStyle(fontSize: 14, color: Colors.black),
    bodyMedium: TextStyle(fontSize: 16, color: Colors.black),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.all(Color(0xFF6A1B9A)),
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
        return const Color(0xFF6A1B9A);
      }
      return Colors.grey;
    }),
    trackColor: MaterialStateProperty.resolveWith<Color?>((states) {
      if (states.contains(MaterialState.selected)) {
        return const Color(0xFFBA68C8);
      }
      return Colors.grey[300];
    }),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: const Color(0xFF6A1B9A),
    foregroundColor: Colors.white,
  ),
  tabBarTheme: TabBarTheme(
    labelColor: const Color(0xFF6A1B9A),
    unselectedLabelColor: Colors.grey[800],
    indicator: const BoxDecoration(
      border: Border(
        bottom: BorderSide(color: Color(0xFF6A1B9A), width: 2),
      ),
    ),
  ),
  useMaterial3: true,
);