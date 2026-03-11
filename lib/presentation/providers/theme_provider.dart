import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  SharedPreferences? _prefs;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadTheme();
  }

  Future<SharedPreferences> get _cachedPrefs async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _loadTheme() async {
    final prefs = await _cachedPrefs;
    final themeString = prefs.getString('themeMode');
    if (themeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == themeString,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    } else {
      // Legacy basic bool fallback
      final isDark = prefs.getBool('isDarkMode');
      if (isDark != null) {
        _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
        notifyListeners();
      }
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await _cachedPrefs;
    await prefs.setString('themeMode', mode.name);
    // Clean up legacy boolean
    await prefs.remove('isDarkMode');
  }

  // Legacy accessor wrapper
  Future<void> toggleTheme(bool isDark) async {
    await setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }
}
