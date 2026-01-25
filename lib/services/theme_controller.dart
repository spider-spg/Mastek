import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({ThemeMode initialMode = ThemeMode.system}) : _mode = initialMode;

  static const String _prefsKey = 'app.themeMode';

  ThemeMode _mode;

  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;
  bool get isLight => _mode == ThemeMode.light;
  bool get isSystem => _mode == ThemeMode.system;

  static Future<ThemeMode> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = (prefs.getString(_prefsKey) ?? 'system').toLowerCase();
    switch (raw) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    String raw;
    switch (mode) {
      case ThemeMode.dark:
        raw = 'dark';
        break;
      case ThemeMode.light:
        raw = 'light';
        break;
      case ThemeMode.system:
      default:
        raw = 'system';
        break;
    }
    await prefs.setString(_prefsKey, raw);
  }

  /// Convenience for a 2-state toggle UI.
  Future<void> setDarkEnabled(bool enabled) => setMode(enabled ? ThemeMode.dark : ThemeMode.light);
}
