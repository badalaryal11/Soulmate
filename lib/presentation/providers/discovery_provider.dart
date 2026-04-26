import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/get_users_usecase.dart';
import '../../domain/repositories/user_repository.dart';
import '../../core/utils/image_generation_service.dart';

import 'current_user_provider.dart';
import '../../core/utils/rate_limiter.dart';

enum DiscoveryStatus { initial, loading, loaded, error }

class DiscoveryProvider extends ChangeNotifier {
  static const int _maxUsers = 200;
  static const int _maxImageUrls = 300;
  static const int _maxSeenIds = 500;
  static const int _minRightSwipesBeforeSimulatedMatch = 1;
  static const int _maxRightSwipesBeforeSimulatedMatch = 3;

  final GetUsersUseCase _getUsersUseCase;
  final CurrentUserProvider _currentUserProvider;
  final UserRepository _userRepository;

  DiscoveryProvider({
    required GetUsersUseCase getUsersUseCase,
    required CurrentUserProvider currentUserProvider,
    required UserRepository userRepository,
  }) : _getUsersUseCase = getUsersUseCase,
       _currentUserProvider = currentUserProvider,
       _userRepository = userRepository {
    _loadSavedFilters();
  }

  Future<void> _loadSavedFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _minAge = prefs.getDouble('filter_min_age') ?? 18;
      _maxAge = prefs.getDouble('filter_max_age') ?? 100;
      _updateFilteredUsers();
      _filterRevision++;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load filters: $e');
    }
  }

  final List<User> _users = [];
  final Set<String> _usedImageUrls = {};
  final Set<String> _seenUserIds = {};
  final Set<String> _swipedUserIds = {};
  final Set<String> _matchedUserIds = {};
  DiscoveryStatus _status = DiscoveryStatus.initial;
  String? _errorMessage;
  bool _isLoadingUsers = false;
  final Random _random = Random();
  int _rightSwipesSinceLastMatch = 0;
  late int _nextSimulatedMatchSwipeTarget =
      _pickNextSimulatedMatchSwipeTarget();

  List<User> get users => _users;
  DiscoveryStatus get status => _status;
  String? get errorMessage => _errorMessage;

  int _filterRevision = 0;
  int get filterRevision => _filterRevision;

  String? _selectedGender;
  String? get selectedGender => _selectedGender;

  double _minAge = 18;
  double _maxAge = 100;
  double get minAge => _minAge;
  double get maxAge => _maxAge;

  List<User> _filteredUsers = [];
  List<User> get filteredUsers => _filteredUsers;

  Function(User)? onMatchFound;

  final List<User> _undoUserStack = [];
  final List<int> _undoIndexStack = [];
  bool get canUndo => _undoUserStack.isNotEmpty;

  void _updateFilteredUsers() {
    final currentUser = _currentUserProvider.currentUser;
    final currentUserInterests = currentUser?.interests ?? [];

    _filteredUsers = _users.where((user) {
      // Exclude already-swiped users from the deck
      if (_swipedUserIds.contains(user.id)) return false;

      final matchesAge = user.age >= _minAge && user.age <= _maxAge;
      final userGender = user.gender.trim().toLowerCase();
      final selected = _selectedGender?.trim().toLowerCase();

      final matchesGender =
          selected == null || selected == 'everyone' || userGender == selected;

      // Filter by shared interests
      bool matchesInterests = true;
      if (currentUserInterests.isNotEmpty && user.interests.isNotEmpty) {
        matchesInterests = user.interests.any(
          (interest) => currentUserInterests.contains(interest),
        );
      }

      return matchesAge && matchesGender && matchesInterests;
    }).toList();
  }

  void updateAgeRange(double min, double max) async {
    _minAge = min;
    _maxAge = max;
    _updateFilteredUsers();
    _filterRevision++;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('filter_min_age', min);
      await prefs.setDouble('filter_max_age', max);
    } catch (e) {
      debugPrint('Failed to save filters: $e');
    }
  }

  Future<void> loadUsers({String? gender, bool clearList = false}) async {
    final currentUser = _currentUserProvider.currentUser;
    if (gender != null) {
      _selectedGender = gender;
    } else if (currentUser?.genderPreference != null) {
      _selectedGender = currentUser!.genderPreference;
    }

    if (clearList) {
      _users.clear();
      _filteredUsers.clear();
      _usedImageUrls.clear();
      _seenUserIds.clear();
      _swipedUserIds.clear();
      _matchedUserIds.clear();
      _rightSwipesSinceLastMatch = 0;
      _nextSimulatedMatchSwipeTarget = _pickNextSimulatedMatchSwipeTarget();
      _filterRevision++;
    }

    // Guard must be checked BEFORE notifyListeners, because the rebuild
    // triggered by notifyListeners can schedule another loadUsers call
    // via addPostFrameCallback before we reach _isLoadingUsers = true.
    if (_isLoadingUsers) return;
    _isLoadingUsers = true;

    if (_users.isEmpty) {
      _status = DiscoveryStatus.loading;
      notifyListeners();
    }

    try {
      // Fetch from Firestore and API via the UseCase
      final allNewUsers = await _getUsersUseCase.call(
        gender: _selectedGender,
        currentUserId: currentUser?.id,
        limit: 20,
        refresh: clearList,
      );

      final List<User> uniqueUsers = [];
      for (var user in allNewUsers) {
        if (_seenUserIds.contains(user.id)) continue;

        String finalUrl = user.imageUrl;
        bool isGenerated = false;

        // API users already have real photos — only generate for Firestore users
        if (!user.id.startsWith('api_') &&
            (finalUrl.isEmpty ||
                (!finalUrl.startsWith('http') &&
                    !finalUrl.startsWith('assets/')))) {
          finalUrl = ImageGenerationService.generateProfileImageUrl(user);
          isGenerated = true;
        }

        // Only run image-URL dedup for generated images (limited pool).
        if (isGenerated) {
          int retryCount = 0;
          while (_usedImageUrls.contains(finalUrl) && retryCount < 10) {
            finalUrl = ImageGenerationService.getFallbackUrl(user, finalUrl);
            retryCount++;
          }
        }

        _seenUserIds.add(user.id);
        _usedImageUrls.add(finalUrl);
        uniqueUsers.add(user.copyWith(imageUrl: finalUrl));
      }

      // Shuffle to mix Firestore + API users randomly
      uniqueUsers.shuffle(Random());
      _users.addAll(uniqueUsers);

      // Belt-and-suspenders: ensure no duplicate IDs in the list
      final seen = <String>{};
      _users.retainWhere((user) => seen.add(user.id));

      if (_users.length > _maxUsers) {
        _users.removeRange(0, _users.length - _maxUsers);
      }
      if (_usedImageUrls.length > _maxImageUrls) {
        final urlList = _usedImageUrls.toList();
        _usedImageUrls.clear();
        _usedImageUrls.addAll(urlList.skip(urlList.length - _maxImageUrls));
      }
      if (_seenUserIds.length > _maxSeenIds) {
        final idList = _seenUserIds.toList();
        _seenUserIds.clear();
        _seenUserIds.addAll(idList.skip(idList.length - _maxSeenIds));
      }
      if (_swipedUserIds.length > _maxSeenIds) {
        final idList = _swipedUserIds.toList();
        _swipedUserIds.clear();
        _swipedUserIds.addAll(idList.skip(idList.length - _maxSeenIds));
      }
      if (_matchedUserIds.length > _maxSeenIds) {
        final idList = _matchedUserIds.toList();
        _matchedUserIds.clear();
        _matchedUserIds.addAll(idList.skip(idList.length - _maxSeenIds));
      }

      final previousCount = _filteredUsers.length;
      _updateFilteredUsers();

      // Rebuild CardSwiper when new unswiped cards become available
      if (_filteredUsers.length != previousCount) {
        _filterRevision++;
      }

      if (_status == DiscoveryStatus.loading ||
          _status == DiscoveryStatus.initial) {
        _status = DiscoveryStatus.loaded;
      }
    } catch (e) {
      if (_users.isEmpty) {
        _status = DiscoveryStatus.error;
        _errorMessage = e.toString();
      }
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  void userSwiped(User swipedUser, CardSwiperDirection direction) {
    // Save for undo
    _undoUserStack.add(swipedUser);
    _undoIndexStack.add(
      0,
    ); // index no longer meaningful; kept for undo stack symmetry
    if (_undoUserStack.length > 10) {
      _undoUserStack.removeAt(0);
      _undoIndexStack.removeAt(0);
    }

    // Mark as swiped so it won't appear again
    _swipedUserIds.add(swipedUser.id);

    if (direction == CardSwiperDirection.right) {
      _handleRightSwipe(swipedUser);
    }

    // Defer deck rebuild to next frame so CardSwiper completes its animation
    // before being destroyed/rebuilt (prevents "deactivated widget" crash)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFilteredUsers();
      _filterRevision++;

      // Pre-load more users when running low
      if (_filteredUsers.length < 10) {
        loadUsers(gender: _selectedGender);
      }

      notifyListeners();
    });
  }

  void undoSwipe() {
    if (!canUndo) return;
    final lastUser = _undoUserStack.removeLast();
    _undoIndexStack.removeLast();

    // Un-mark as swiped so it reappears
    _swipedUserIds.remove(lastUser.id);
    _updateFilteredUsers();
    _filterRevision++;
    notifyListeners();
  }

  void _handleRightSwipe(User swipedUser) {
    final currentUser = _currentUserProvider.currentUser;
    if (currentUser == null) return;
    _rightSwipesSinceLastMatch++;

    // Persist "like" so mutual matches can be detected in future sessions.
    if (!currentUser.favoriteUserIds.contains(swipedUser.id)) {
      final updatedFavorites = List<String>.from(currentUser.favoriteUserIds)
        ..add(swipedUser.id);

      _currentUserProvider.updateLocalUser(
        currentUser.copyWith(favoriteUserIds: updatedFavorites),
      );

      unawaited(
        _userRepository
            .updateUserField(currentUser.id, {
              'favoriteUserIds': updatedFavorites,
            })
            .catchError((e) {
              debugPrint('Failed to persist like for ${swipedUser.id}: $e');
            }),
      );
    }

    if (_matchedUserIds.contains(swipedUser.id)) return;

    final isMutualLike = swipedUser.favoriteUserIds.contains(currentUser.id);
    bool hasMatch = isMutualLike;

    // Make simulated matches feel more playful by waiting for a random number
    // of right swipes before allowing a chance-based match.
    if (!hasMatch) {
      final canAttemptSimulatedMatch =
          _rightSwipesSinceLastMatch >= _nextSimulatedMatchSwipeTarget;
      if (!canAttemptSimulatedMatch) return;

      final isSyntheticProfile =
          swipedUser.id.startsWith('api_') ||
          swipedUser.id.startsWith('local_');
      final simulatedMatchChancePercent = isSyntheticProfile ? 70 : 50;
      hasMatch = _random.nextInt(100) < simulatedMatchChancePercent;
    }

    if (!hasMatch) return;

    if (RateLimiter.check(
      'swipe_match_trigger_${swipedUser.id}',
      const Duration(seconds: 1),
    )) {
      _matchedUserIds.add(swipedUser.id);
      onMatchFound?.call(swipedUser);
      _rightSwipesSinceLastMatch = 0;
      _nextSimulatedMatchSwipeTarget = _pickNextSimulatedMatchSwipeTarget();
    }
  }

  int _pickNextSimulatedMatchSwipeTarget() {
    final range =
        _maxRightSwipesBeforeSimulatedMatch -
        _minRightSwipesBeforeSimulatedMatch +
        1;
    return _minRightSwipesBeforeSimulatedMatch + _random.nextInt(range);
  }
}
