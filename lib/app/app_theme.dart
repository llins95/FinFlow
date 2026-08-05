import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData dark = ThemeData(
    useMaterial3: true,

    brightness: Brightness.dark,

    colorSchemeSeed: Colors.blue,

    scaffoldBackgroundColor: const Color(0xff121212),

    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: Color(0xff121212),
      elevation: 0,
    ),

    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.all(12),
      clipBehavior: Clip.antiAlias,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xff1c1c1e),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
