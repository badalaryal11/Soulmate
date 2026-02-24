import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import '../../domain/entities/user_model.dart';

class DailyPicksService {
  static const String _storageKey = 'daily_picks_date';
  static const String _usersKey = 'daily_picks_users';

  Future<List<User>> getDailyPicks(List<User> allUsers) async {
    if (allUsers.isEmpty) return [];

    final prefs = await SharedPreferences.getInstance();
    final lastPickDate = prefs.getString(_storageKey);
    final today = DateTime.now().toIso8601String().split('T').first;

    if (lastPickDate == today) {
      // Return cached picks
      final storedIds = prefs.getStringList(_usersKey) ?? [];
      return allUsers.where((u) => storedIds.contains(u.id)).toList();
    } else {
      // Generate new picks
      final random = math.Random();
      final pickCount =
          5 + random.nextInt(6); // Random number between 5 and 10 inclusive
      final shuffled = List<User>.from(allUsers)..shuffle();
      final newPicks = shuffled.take(pickCount).toList();

      // Save
      await prefs.setString(_storageKey, today);
      await prefs.setStringList(_usersKey, newPicks.map((u) => u.id).toList());

      return newPicks;
    }
  }
}
