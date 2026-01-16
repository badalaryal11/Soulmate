import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

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

  String? _selectedGender;

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

  void userSwiped(int index) {
    // You might want to pre-fetch more users when list gets low
    if (index >= _users.length - 5) {
      loadUsers();
    }
  }
}
