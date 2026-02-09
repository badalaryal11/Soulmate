import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/database_service.dart';

enum UserStatus { initial, loading, loaded, error }

class UserProvider extends ChangeNotifier {
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
  UserStatus _status = UserStatus.initial;
  String? _errorMessage;

  List<User> get users => _users;
  UserStatus get status => _status;
  String? get errorMessage => _errorMessage;

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
      final matchesGender =
          _selectedGender == null ||
          _selectedGender == 'everyone' ||
          user.gender.toLowerCase() == _selectedGender?.toLowerCase();
      return matchesAge && matchesGender;
    }).toList();
  }

  void updateAgeRange(double min, double max) {
    _minAge = min;
    _maxAge = max;
    _updateFilteredUsers();
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
        _currentUserInterests = _currentUser!.interests;
        // Load gender preference
        if (_currentUser!.genderPreference != null) {
          _selectedGender = _currentUser!.genderPreference;
        }
      }
      notifyListeners();
    }
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
    }

    _status = UserStatus.loading;
    notifyListeners();

    try {
      final newUsers = await _userRepository.getUsers(gender: _selectedGender);
      _users.addAll(newUsers);
      _updateFilteredUsers();
      _status = UserStatus.loaded;
    } catch (e) {
      _status = UserStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
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
        notifyListeners();
      }
      onMatchFound?.call(user);
    }
  }

  void unmatchUser(String userId) {
    _matches.removeWhere((user) => user.id == userId);
    notifyListeners();
  }
}
