import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/get_users_usecase.dart';
import '../../core/utils/image_generation_service.dart';

import 'current_user_provider.dart';
import '../../core/utils/rate_limiter.dart';

enum DiscoveryStatus { initial, loading, loaded, error }

class DiscoveryProvider extends ChangeNotifier {
  static const int _maxUsers = 200;
  static const int _maxImageUrls = 300;

  final GetUsersUseCase _getUsersUseCase;
  final CurrentUserProvider _currentUserProvider;

  DiscoveryProvider({
    required GetUsersUseCase getUsersUseCase,
    required CurrentUserProvider currentUserProvider,
  }) : _getUsersUseCase = getUsersUseCase,
       _currentUserProvider = currentUserProvider;

  final List<User> _users = [];
  final Set<String> _usedImageUrls = {};
  final Set<String> _seenUserIds = {};
  final Set<String> _swipedUserIds = {};
  DiscoveryStatus _status = DiscoveryStatus.initial;
  String? _errorMessage;
  bool _isLoadingUsers = false;

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

  int _swipeCount = 0;
  int _nextMatchThreshold = 3;
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

  void updateAgeRange(double min, double max) {
    _minAge = min;
    _maxAge = max;
    _updateFilteredUsers();
    _filterRevision++;
    notifyListeners();
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
    _undoIndexStack.add(0); // index no longer meaningful; kept for undo stack symmetry
    if (_undoUserStack.length > 10) {
      _undoUserStack.removeAt(0);
      _undoIndexStack.removeAt(0);
    }

    // Mark as swiped so it won't appear again
    _swipedUserIds.add(swipedUser.id);

    if (direction == CardSwiperDirection.right) {
      _swipeCount++;
      if (_swipeCount >= _nextMatchThreshold) {
        if (RateLimiter.check(
          'swipe_match_trigger',
          const Duration(seconds: 1),
        )) {
          onMatchFound?.call(swipedUser);
          _swipeCount = 0;
          _nextMatchThreshold = 5 + (DateTime.now().millisecond % 5);
        }
      }
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
}
