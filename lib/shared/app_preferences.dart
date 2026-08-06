import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../controllers/theme_controller.dart';

class AppPreferences {
  static const boxName = 'app_preferences';
  static const _themeModeKey = 'theme_mode';

  static Box<dynamic> get _box => Hive.box<dynamic>(boxName);

  static ThemeMode loadThemeMode() {
    return ThemeController.fromStorage(_box.get(_themeModeKey));
  }

  static Future<void> saveThemeMode(ThemeMode mode) {
    return _box.put(_themeModeKey, ThemeController.toStorage(mode));
  }
}
