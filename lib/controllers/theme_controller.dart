import 'package:flutter/material.dart';

typedef ThemeModePersistence = Future<void> Function(ThemeMode mode);

class ThemeController extends ChangeNotifier {
  factory ThemeController({
    ThemeMode initialMode = ThemeMode.system,
    ThemeModePersistence? persist,
  }) {
    return ThemeController._(initialMode, persist);
  }

  ThemeController._(this._mode, this._persist);

  ThemeMode _mode;
  final ThemeModePersistence? _persist;

  ThemeMode get mode => _mode;

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) {
      return;
    }

    _mode = mode;
    notifyListeners();
    await _persist?.call(mode);
  }

  static ThemeMode fromStorage(Object? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static String toStorage(ThemeMode mode) => mode.name;
}
