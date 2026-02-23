import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../../domain/entities/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/datasources/auth_service.dart';
import '../../data/datasources/database_service.dart';
import '../../data/datasources/image_generation_service.dart';

enum UserStatus { initial, loading, loaded, error }

class UserProvider extends ChangeNotifier {
  // Memory caps to prevent unbounded growth
  static const int _maxUsers = 200;
  static const int _maxImageUrls = 300;

  final UserRepository _userRepository;
  final AuthService _authService;
  final DatabaseService _databaseService;

  UserProvider({
    UserRepository? userRepository,
    AuthService? authService,
    DatabaseService? databaseService,
  }) : _userRepository = userRepository ?? UserRepository(),
       _authService = authService ?? AuthService(),
       _databaseService = databaseService ?? DatabaseService();

  final List<User> _users = [];
  final Set<String> _usedImageUrls =
      {}; // Track displayed images to prevent duplicates
  UserStatus _status = UserStatus.initial;
  String? _errorMessage;

  List<User> get users => _users;
  UserStatus get status => _status;
  String? get errorMessage => _errorMessage;

  int _filterRevision = 0;
  int get filterRevision => _filterRevision;

  List<String> _currentUserInterests = [];
  String? _selectedGender;
  User? _currentUser;

  List<String> get currentUserInterests => _currentUserInterests;
  User? get currentUser => _currentUser;
  String? get selectedGender => _selectedGender;

  double _minAge = 18;
  double _maxAge = 100;

  double get minAge => _minAge;
  double get maxAge => _maxAge;

  List<User> _filteredUsers = [];
  List<User> get filteredUsers => _filteredUsers;

  void _updateFilteredUsers() {
    _filteredUsers = _users.where((user) {
      final matchesAge = user.age >= _minAge && user.age <= _maxAge;
      final userGender = user.gender.trim().toLowerCase();
      final selected = _selectedGender?.trim().toLowerCase();

      final matchesGender =
          selected == null || selected == 'everyone' || userGender == selected;
      return matchesAge && matchesGender;
    }).toList();
  }

  void updateAgeRange(double min, double max) {
    _minAge = min;
    _maxAge = max;
    _updateFilteredUsers();
    _filterRevision++; // Force swiper reset
    notifyListeners();
  }

  void setInterests(List<String> interests) {
    _currentUserInterests = interests;
    notifyListeners();
  }

  Future<void> loadCurrentUser() async {
    final user = _authService.currentUser;
    if (user != null) {
      _currentUser = await _databaseService.getUser(user.uid);
      if (_currentUser != null) {
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
          await _databaseService.updateUserField(_currentUser!.id, {
            'streak': newStreak,
            'coins': newCoins,
            'lastLoginDate': newLastLogin,
          });
          _currentUser = _currentUser!.copyWith(
            streak: newStreak,
            coins: newCoins,
            lastLoginDate: newLastLogin,
          );
        }

        _currentUserInterests = _currentUser!.interests;
        if (_currentUser!.genderPreference != null) {
          _selectedGender = _currentUser!.genderPreference;
        }
        loadMatches(); // Load chats/matches
      }
      notifyListeners();
    }
  }

  void updateLocalUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> loadUsers({String? gender, bool clearList = false}) async {
    // Priority: 1. Argument 2. stored preference 3. default (null/all)
    if (gender != null) {
      _selectedGender = gender;
    } else if (_currentUser?.genderPreference != null) {
      _selectedGender = _currentUser!.genderPreference;
    } else {
      // Fallback or keep existing _selectedGender
    }

    if (clearList) {
      _users.clear();
      _filteredUsers.clear();
      _filterRevision++; // Force swiper reset on full reload/filter change
    }

    // Optimization: Silent loading
    // Only set loading status if it's the initial load or a full refresh (users empty)
    // If we have users and are just fetching more, don't show loading state
    if (_users.isEmpty && !clearList) {
      _status = UserStatus.loading;
      notifyListeners();
    }

    try {
      final newUsers = await _userRepository.getUsers(
        gender: _selectedGender,
        currentUserId: _currentUser?.id,
      );

      // Strict Deduplication Logic
      final List<User> uniqueUsers = [];
      for (var user in newUsers) {
        String finalUrl = user.imageUrl;

        // Ensure URL is valid (fallback to generated if empty/invalid)
        if (finalUrl.isEmpty ||
            (!finalUrl.startsWith('http') && !finalUrl.startsWith('assets/'))) {
          finalUrl = ImageGenerationService.generateProfileImageUrl(user);
        }

        // Check for duplicates
        int retryCount = 0;
        while (_usedImageUrls.contains(finalUrl) && retryCount < 10) {
          // Regeneration strategy:
          // Use ImageGenerationService fallback to get an alternative URL
          finalUrl = ImageGenerationService.getFallbackUrl(user, finalUrl);
          retryCount++;
        }

        _usedImageUrls.add(finalUrl);
        uniqueUsers.add(user.copyWith(imageUrl: finalUrl));
      }

      _users.addAll(uniqueUsers);

      // Trim old entries if exceeding memory cap
      if (_users.length > _maxUsers) {
        _users.removeRange(0, _users.length - _maxUsers);
      }
      if (_usedImageUrls.length > _maxImageUrls) {
        final urlList = _usedImageUrls.toList();
        _usedImageUrls.clear();
        _usedImageUrls.addAll(urlList.skip(urlList.length - _maxImageUrls));
      }

      _updateFilteredUsers();

      // If we were in a loading state, mark as loaded
      // If we were silently loading, we stay 'loaded' but have new data
      if (_status == UserStatus.loading || _status == UserStatus.initial) {
        _status = UserStatus.loaded;
      }
    } catch (e) {
      // Only show error screen if we have no users
      if (_users.isEmpty) {
        _status = UserStatus.error;
        _errorMessage = e.toString();
      }
      // If we have users, maybe show a snackbar (omitted for now to keep flow smooth)
    }
    notifyListeners();
  }

  Future<void> loadMatches() async {
    if (_currentUser == null) return;

    try {
      final chatDocs = await _databaseService.getActiveChats(_currentUser!.id);
      final List<User> loadedMatches = [];

      for (var chat in chatDocs) {
        final participants = List<String>.from(chat['participants'] ?? []);
        final otherUserId = participants.firstWhere(
          (id) => id != _currentUser!.id,
          orElse: () => '',
        );

        if (otherUserId.isNotEmpty) {
          // Fetch user profile
          // Optimization: Check if we have it in _users first?
          // Check _users list?
          User? user;
          try {
            user = _users.firstWhere((u) => u.id == otherUserId);
          } catch (e) {
            // Not found locally
          }

          user ??= await _databaseService.getUser(otherUserId);

          if (user != null) {
            // Inject streak
            final streak = chat['streak'] ?? 0;
            loadedMatches.add(user.copyWith(streak: streak));
          }
        }
      }

      _matches.clear();
      _matches.addAll(loadedMatches);
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading matches: $e");
    }
  }

  int _swipeCount = 0;
  int _nextMatchThreshold = 3; // Initial low threshold for demo

  // Use a simple callback for match event to keep it lightweight, or a Stream
  Function(User)? onMatchFound;

  // Matches
  final List<User> _matches = [];
  List<User> get matches => _matches;

  void userSwiped(int index, CardSwiperDirection direction) {
    // Only count as a potential match if the user swiped RIGHT (Like)
    if (direction == CardSwiperDirection.right) {
      _swipeCount++;

      // Check for match
      if (_swipeCount >= _nextMatchThreshold) {
        _triggerMatch(index);
        _swipeCount = 0;
        _nextMatchThreshold =
            5 + (DateTime.now().millisecond % 5); // Random threshold 5-9
      }
    }

    if (index >= filteredUsers.length - 5) {
      loadUsers(gender: _selectedGender);
    }
  }

  void _triggerMatch(int index) {
    if (index < filteredUsers.length) {
      final user = filteredUsers[index];
      // Avoid duplicate matches
      if (!_matches.any((m) => m.id == user.id)) {
        _matches.add(user);

        // Also simpler: verify if we should save this "match" to the DB so it persists?
        // For now, let's just rely on them SENDING a message to start the persistence (chat creation).
        // The implementation plan mainly focused on CHAT streaks, implying active chats.

        notifyListeners();
      }
      onMatchFound?.call(user);
    }
  }

  Future<void> unmatchUser(String userId) async {
    _matches.removeWhere((user) => user.id == userId);
    notifyListeners();

    if (_currentUser != null) {
      final chatId = _databaseService.getChatId(_currentUser!.id, userId);
      await _databaseService.deleteChat(chatId);
    }
  }
}
