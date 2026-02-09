import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soulmate/presentation/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeProvider', () {
    test('initial theme is system', () {
      SharedPreferences.setMockInitialValues({});
      final themeProvider = ThemeProvider();
      expect(themeProvider.themeMode, ThemeMode.system);
    });

    test('loads theme from shared preferences', () async {
      SharedPreferences.setMockInitialValues({'isDarkMode': true});
      final themeProvider = ThemeProvider();

      // Wait for async load to complete.
      // Since _loadTheme is called in constructor and we can't await it,
      // we need to give it a moment or rely on testing logic that allows async init.
      // However, a better approach for testability is to expose loadTheme or await a future.
      // But let's try waiting.
      await Future.delayed(Duration.zero);

      expect(themeProvider.isDarkMode, true);
      expect(themeProvider.themeMode, ThemeMode.dark);
    });

    test('toggleTheme updates theme and saves to prefs', () async {
      SharedPreferences.setMockInitialValues({});
      final themeProvider = ThemeProvider();

      await themeProvider.toggleTheme(true);

      expect(themeProvider.isDarkMode, true);
      expect(themeProvider.themeMode, ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('isDarkMode'), true);
    });
  });
}
