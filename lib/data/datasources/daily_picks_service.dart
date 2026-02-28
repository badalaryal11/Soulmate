import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import '../../domain/entities/user.dart';

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
      // Generate new picks using random indices (avoids copying full list)
      final random = math.Random();
      final pickCount = math.min(
        5 + random.nextInt(6), // 5-10 inclusive
        allUsers.length,
      );

      final indices = <int>{};
      while (indices.length < pickCount) {
        indices.add(random.nextInt(allUsers.length));
      }
      final newPicks = indices.map((i) => allUsers[i]).toList();

      // Save
      await prefs.setString(_storageKey, today);
      await prefs.setStringList(_usersKey, newPicks.map((u) => u.id).toList());

      return newPicks;
    }
  }
}
