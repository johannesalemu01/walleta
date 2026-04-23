import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

class ThemeProvider extends ChangeNotifier {
  static const _key = 'themeMode';

  AppThemeMode _mode = AppThemeMode.system;

  AppThemeMode get mode => _mode;

  bool isDark(BuildContext context) {
    if (_mode == AppThemeMode.dark) return true;
    if (_mode == AppThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  ThemeMode get themeMode {
    switch (_mode) {
      case AppThemeMode.dark: return ThemeMode.dark;
      case AppThemeMode.light: return ThemeMode.light;
      case AppThemeMode.system: return ThemeMode.system;
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(_key);
    switch (val) {
      case 'dark': _mode = AppThemeMode.dark; break;
      case 'light': _mode = AppThemeMode.light; break;
      default: _mode = AppThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setMode(AppThemeMode mode) async {
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
    notifyListeners();
  }
}
