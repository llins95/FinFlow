import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../controllers/theme_controller.dart';

class AppPreferences {
  static const boxName = 'app_preferences';
  static const _themeModeKey = 'theme_mode';
  static const _dataResetPrefix = 'data_reset_id_';

  static Box<dynamic> get _box => Hive.box<dynamic>(boxName);

  static ThemeMode loadThemeMode() {
    return ThemeController.fromStorage(_box.get(_themeModeKey));
  }

  static Future<void> saveThemeMode(ThemeMode mode) {
    return _box.put(_themeModeKey, ThemeController.toStorage(mode));
  }

  static String? loadDataResetId(String userId) {
    return _box.get('$_dataResetPrefix$userId') as String?;
  }

  static Future<void> saveDataResetId(String userId, String resetId) {
    return _box.put('$_dataResetPrefix$userId', resetId);
  }
}
