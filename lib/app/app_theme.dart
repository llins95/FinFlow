import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light = _build(Brightness.light);
  static ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff0078d4),
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(centerTitle: false, elevation: 0, backgroundColor: scheme.surface),
      cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.all(12)),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      navigationBarTheme: const NavigationBarThemeData(height: 72),
    );
  }
}
