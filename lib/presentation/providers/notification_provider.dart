import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  bool _areNotificationsEnabled = true;
  SharedPreferences? _prefs;

  bool get areNotificationsEnabled => _areNotificationsEnabled;

  NotificationProvider() {
    _loadPreferences();
  }

  Future<SharedPreferences> get _cachedPrefs async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _loadPreferences() async {
    final prefs = await _cachedPrefs;
    _areNotificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    notifyListeners();
  }

  Future<void> toggleNotifications(bool isEnabled) async {
    _areNotificationsEnabled = isEnabled;
    notifyListeners();
    final prefs = await _cachedPrefs;
    await prefs.setBool('notifications_enabled', isEnabled);

    if (!isEnabled) {
      await NotificationService().cancelAll();
    }
  }
}
