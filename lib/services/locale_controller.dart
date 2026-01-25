import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  LocaleController({Locale? initialLocale}) : _locale = initialLocale;

  static const _prefsKey = 'ui.locale';

  Locale? _locale;

  Locale? get locale => _locale;

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
    Locale('bn'),
    Locale('te'),
    Locale('ta'),
    Locale('gu'),
    Locale('kn'),
    Locale('ml'),
    Locale('pa'),
    Locale('or'),
    Locale('as'),
    Locale('ur'),
  ];

  static Locale? _parseLocale(String? code) {
    final v = (code ?? '').trim();
    if (v.isEmpty || v == 'auto' || v == 'system') return null;
    final parts = v.split('_');
    if (parts.isEmpty) return null;
    return Locale(parts.first);
  }

  static Future<LocaleController> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    return LocaleController(initialLocale: _parseLocale(saved));
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.setString(_prefsKey, 'system');
    } else {
      await prefs.setString(_prefsKey, locale.languageCode);
    }
  }

  Future<void> setFromLanguageCode(String code) async {
    await setLocale(_parseLocale(code));
  }
}
