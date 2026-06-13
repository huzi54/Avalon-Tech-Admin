import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsProvider extends ChangeNotifier {
  static const _themeModeKey = 'themeMode';
  static const _languageCodeKey = 'languageCode';

  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('en', 'CA');
  bool _isLoaded = false;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _themeMode = _themeModeFromName(
      preferences.getString(_themeModeKey) ?? ThemeMode.light.name,
    );
    final languageCode = preferences.getString(_languageCodeKey) ?? 'en';
    _locale = Locale(languageCode == 'fr' ? 'fr' : 'en', 'CA');
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    if (_themeMode == value) return;
    _themeMode = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeModeKey, value.name);
  }

  Future<void> setLocale(Locale value) async {
    final normalized = Locale(value.languageCode == 'fr' ? 'fr' : 'en', 'CA');
    if (_locale == normalized) return;
    _locale = normalized;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_languageCodeKey, normalized.languageCode);
  }

  ThemeMode _themeModeFromName(String value) {
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.light,
    );
  }
}
