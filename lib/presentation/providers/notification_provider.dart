import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  bool _matchesEnabled = true;
  bool _messagesEnabled = true;
  bool _engagementEnabled = true;

  SharedPreferences? _prefs;
  final NotificationRepository _notificationRepository;

  bool get matchesEnabled => _matchesEnabled;
  bool get messagesEnabled => _messagesEnabled;
  bool get engagementEnabled => _engagementEnabled;

  NotificationProvider({required NotificationRepository notificationRepository})
    : _notificationRepository = notificationRepository {
    _loadPreferences();
  }

  Future<SharedPreferences> get _cachedPrefs async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _loadPreferences() async {
    final prefs = await _cachedPrefs;
    _matchesEnabled = prefs.getBool('notifications_matches') ?? true;
    _messagesEnabled = prefs.getBool('notifications_messages') ?? true;
    _engagementEnabled = prefs.getBool('notifications_engagement') ?? true;
    await _notificationRepository.syncPushPreferences(
      matchesEnabled: _matchesEnabled,
      messagesEnabled: _messagesEnabled,
      engagementEnabled: _engagementEnabled,
    );
    notifyListeners();
  }

  Future<void> toggleMatches(bool isEnabled) async {
    _matchesEnabled = isEnabled;
    notifyListeners();
    final prefs = await _cachedPrefs;
    await prefs.setBool('notifications_matches', isEnabled);
    await _notificationRepository.syncPushPreferences(
      matchesEnabled: _matchesEnabled,
      messagesEnabled: _messagesEnabled,
      engagementEnabled: _engagementEnabled,
    );
  }

  Future<void> toggleMessages(bool isEnabled) async {
    _messagesEnabled = isEnabled;
    notifyListeners();
    final prefs = await _cachedPrefs;
    await prefs.setBool('notifications_messages', isEnabled);
    await _notificationRepository.syncPushPreferences(
      matchesEnabled: _matchesEnabled,
      messagesEnabled: _messagesEnabled,
      engagementEnabled: _engagementEnabled,
    );
  }

  Future<void> toggleEngagement(bool isEnabled) async {
    _engagementEnabled = isEnabled;
    notifyListeners();
    final prefs = await _cachedPrefs;
    await prefs.setBool('notifications_engagement', isEnabled);
    await _notificationRepository.syncPushPreferences(
      matchesEnabled: _matchesEnabled,
      messagesEnabled: _messagesEnabled,
      engagementEnabled: _engagementEnabled,
    );
    if (!isEnabled) {
      await _notificationRepository.cancelNotification(99); // Engagement Notification ID
    }
  }
}
