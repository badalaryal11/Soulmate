import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/database_service.dart';

enum UserStatus { initial, loading, loaded, error }

class UserProvider extends ChangeNotifier {
  final UserRepository _userRepository;

  UserProvider({UserRepository? userRepository})
    : _userRepository = userRepository ?? UserRepository();

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

  void setInterests(List<String> interests) {
    _currentUserInterests = interests;
    notifyListeners();
  }

  Future<void> loadCurrentUser() async {
    final user = AuthService().currentUser;
    if (user != null) {
      _currentUser = await DatabaseService().getUser(user.uid);
      if (_currentUser != null) {
        _currentUserInterests = _currentUser!.interests;
      }
      notifyListeners();
    }
  }

  Future<void> loadUsers({String? gender}) async {
    if (gender != null) _selectedGender = gender;

    _status = UserStatus.loading;
    notifyListeners();

    try {
      final newUsers = await _userRepository.getUsers(gender: _selectedGender);
      _users.addAll(newUsers);
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

  void userSwiped(int index) {
    _swipeCount++;

    // Check for match
    if (_swipeCount >= _nextMatchThreshold) {
      _triggerMatch(index);
      _swipeCount = 0;
      _nextMatchThreshold =
          5 + (DateTime.now().millisecond % 5); // Random threshold 5-9
    }

    if (index >= _users.length - 5) {
      loadUsers(gender: _selectedGender);
    }
  }

  void _triggerMatch(int index) {
    if (index < _users.length) {
      final user = _users[index];
      onMatchFound?.call(user);
    }
  }
}
