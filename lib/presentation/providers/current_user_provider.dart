import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/usecases/get_current_user_usecase.dart';

class CurrentUserProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final UserRepository _userRepository; // Used for silent updates like streaks

  CurrentUserProvider({
    required AuthRepository authRepository,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required UserRepository userRepository,
  }) : _authRepository = authRepository,
       _getCurrentUserUseCase = getCurrentUserUseCase,
       _userRepository = userRepository;

  User? _currentUser;
  User? get currentUser => _currentUser;

  Future<void> loadCurrentUser() async {
    final user = _authRepository.currentUser;
    if (user != null) {
      _currentUser = await _getCurrentUserUseCase(user.uid);
      if (_currentUser != null) {
        _handleDailyLogin();
      }
      notifyListeners();
    }
  }

  void updateLocalUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  void _handleDailyLogin() {
    // Daily login logic (Streak & Coins)
    final today = DateTime.now();
    final lastLoginStr = _currentUser!.lastLoginDate;
    DateTime? lastLogin;
    if (lastLoginStr != null && lastLoginStr.isNotEmpty) {
      lastLogin = DateTime.tryParse(lastLoginStr);
    }

    bool shouldUpdate = false;
    int newStreak = _currentUser!.streak;
    int newCoins = _currentUser!.coins;

    if (lastLogin == null) {
      shouldUpdate = true;
      newStreak = 1;
      newCoins += 10; // Initial Daily Reward
    } else {
      final isSameDay =
          today.year == lastLogin.year &&
          today.month == lastLogin.month &&
          today.day == lastLogin.day;

      if (!isSameDay) {
        shouldUpdate = true;
        // Check if it was yesterday
        final yesterday = today.subtract(const Duration(days: 1));
        final isYesterday =
            yesterday.year == lastLogin.year &&
            yesterday.month == lastLogin.month &&
            yesterday.day == lastLogin.day;

        if (isYesterday) {
          newStreak++;
        } else {
          newStreak = 1; // Reset
        }

        // Reward formula: 10 base + streak bonus (cap at 10 bonus)
        int streakBonus = newStreak > 10 ? 10 : newStreak;
        newCoins += 10 + streakBonus;
      }
    }

    if (shouldUpdate) {
      final newLastLogin = today.toIso8601String();
      // Fire-and-forget
      _userRepository
          .updateUserField(_currentUser!.id, {
            'streak': newStreak,
            'coins': newCoins,
            'lastLoginDate': newLastLogin,
          })
          .catchError((e) {
            debugPrint("Failed to update streak/coins: $e");
          });
      _currentUser = _currentUser!.copyWith(
        streak: newStreak,
        coins: newCoins,
        lastLoginDate: newLastLogin,
      );
    }
  }
}
