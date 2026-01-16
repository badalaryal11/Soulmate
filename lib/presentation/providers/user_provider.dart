import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

enum UserStatus { initial, loading, loaded, error }

class UserProvider extends ChangeNotifier {
  final UserRepository _userRepository;

  UserProvider({UserRepository? userRepository})
    : _userRepository = userRepository ?? UserRepository();

  List<User> _users = [];
  UserStatus _status = UserStatus.initial;
  String? _errorMessage;

  List<User> get users => _users;
  UserStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Future<void> loadUsers() async {
    _status = UserStatus.loading;
    notifyListeners();

    try {
      final newUsers = await _userRepository.getUsers();
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
