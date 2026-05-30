import 'package:hive_flutter/hive_flutter.dart';

class HiveStorage {
  static const String _settingsBox = 'snap_settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_settingsBox);
  }

  // Helper for generic settings
  Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box(_settingsBox);
    await box.put(key, value);
  }

  dynamic getSetting(String key, dynamic defaultValue) {
    final box = Hive.box(_settingsBox);
    return box.get(key, defaultValue: defaultValue);
  }
}
