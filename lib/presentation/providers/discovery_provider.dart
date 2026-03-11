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
      _filterRevision++;
    }

    if (_users.isEmpty) {
      _status = DiscoveryStatus.loading;
      notifyListeners();
    }

    if (_isLoadingUsers) return;
    _isLoadingUsers = true;

    try {
      final newUsers = await _getUsersUseCase.call(
        gender: _selectedGender,
        currentUserId: currentUser?.id,
        refresh: clearList,
      );

      final List<User> uniqueUsers = [];
      for (var user in newUsers) {
        if (_seenUserIds.contains(user.id)) continue;

        String finalUrl = user.imageUrl;
        if (finalUrl.isEmpty ||
            (!finalUrl.startsWith('http') && !finalUrl.startsWith('assets/'))) {
          finalUrl = ImageGenerationService.generateProfileImageUrl(user);
        }

        int retryCount = 0;
        while (_usedImageUrls.contains(finalUrl) && retryCount < 10) {
          finalUrl = ImageGenerationService.getFallbackUrl(user, finalUrl);
          retryCount++;
        }

        _seenUserIds.add(user.id);
        _usedImageUrls.add(finalUrl);
        uniqueUsers.add(user.copyWith(imageUrl: finalUrl));
      }

      _users.addAll(uniqueUsers);

      if (_users.length > _maxUsers) {
        _users.removeRange(0, _users.length - _maxUsers);
      }
      if (_usedImageUrls.length > _maxImageUrls) {
        final urlList = _usedImageUrls.toList();
        _usedImageUrls.clear();
        _usedImageUrls.addAll(urlList.skip(urlList.length - _maxImageUrls));
      }

      _updateFilteredUsers();

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

  void userSwiped(int index, CardSwiperDirection direction) {
    bool stateChanged = false;
    if (index < filteredUsers.length) {
      _undoUserStack.add(filteredUsers[index]);
      _undoIndexStack.add(index);
      if (_undoUserStack.length > 10) {
        _undoUserStack.removeAt(0);
        _undoIndexStack.removeAt(0);
      }
      stateChanged = true;
    }

    if (direction == CardSwiperDirection.right) {
      _swipeCount++;
      if (_swipeCount >= _nextMatchThreshold) {
        // Prevent rapid swiping from queuing up multiple matches simultaneously
        if (RateLimiter.check(
          'swipe_match_trigger',
          const Duration(seconds: 1),
        )) {
          _triggerMatch(index);
          _swipeCount = 0;
          _nextMatchThreshold = 5 + (DateTime.now().millisecond % 5);
        }
      }
    }

    if (index >= filteredUsers.length - 5) {
      loadUsers(gender: _selectedGender);
    }

    if (stateChanged) notifyListeners();
  }

  void undoSwipe() {
    if (!canUndo) return;
    final lastUser = _undoUserStack.removeLast();
    final lastIndex = _undoIndexStack.removeLast();
    final insertIndex = lastIndex.clamp(0, filteredUsers.length);
    _filteredUsers.insert(insertIndex, lastUser);
    notifyListeners();
  }

  void _triggerMatch(int index) {
    if (index < filteredUsers.length) {
      final user = filteredUsers[index];
      onMatchFound?.call(user);
    }
  }
}
