import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/user.dart';

class ReqresApiService {
  static const String _baseUrl = 'https://reqres.in/api/users';
  static final http.Client _client = http.Client();
  static final Random _random = Random();
  static final List<User> _userCache = [];
  static bool _isFetching = false;

  static const List<String> _bios = [
    'Always looking for new adventures 🌍',
    'Tech enthusiast & coffee addict ☕',
    'Love hiking and photography 📸',
    'Foodie searching for the best pizza 🍕',
    'Music lover and aspiring guitarist 🎸',
    'Bookworm and amateur writer 📚',
    'Dog person and weekend explorer 🐕',
    'Fitness junkie and early riser 🌅',
    'Art lover and museum wanderer 🎨',
    'Movie buff and popcorn connoisseur 🍿',
  ];

  static const List<String> _interests = [
    'Travel', 'Music', 'Photography', 'Cooking', 'Reading',
    'Fitness', 'Movies', 'Art', 'Dancing', 'Hiking',
    'Gaming', 'Yoga', 'Coffee', 'Nature', 'Sports'
  ];

  static Future<List<User>> fetchUsers({int count = 6, String? gender}) async {
    if (_userCache.length >= count) {
      final users = _userCache.sublist(0, count);
      _userCache.removeRange(0, count);
      _refillCacheInBackground();
      return users;
    }

    _isFetching = true;
    try {
      final apiUsers = await _fetchFromApi();
      if (apiUsers.isNotEmpty) {
        if (apiUsers.length > count) {
          final toReturn = apiUsers.sublist(0, count);
          _userCache.addAll(apiUsers.sublist(count));
          return toReturn;
        }
        return apiUsers;
      }
    } finally {
      _isFetching = false;
    }

    return [];
  }

  static Future<void> _refillCacheInBackground() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      final newUsers = await _fetchFromApi();
      if (newUsers.isNotEmpty) {
        _userCache.addAll(newUsers);
      }
    } finally {
      _isFetching = false;
    }
  }

  static Future<List<User>> _fetchFromApi() async {
    try {
      // ReqRes has pages 1 and 2
      final page = _random.nextInt(2) + 1;
      final uri = Uri.parse('$_baseUrl?page=$page&per_page=6');
      final response = await _client.get(uri).timeout(const Duration(seconds: 2));

      if (response.statusCode != 200) {
        return [];
      }

      final data = json.decode(response.body);
      final usersJson = data['data'] as List<dynamic>?;
      if (usersJson == null) return [];

      return usersJson.map<User>((json) {
        final id = 'reqres_${json['id']}';
        final firstName = json['first_name'] as String;
        final lastName = json['last_name'] as String;
        final avatar = json['avatar'] as String;
        
        final age = 18 + _random.nextInt(15);
        final bio = _bios[_random.nextInt(_bios.length)];
        
        final userInterests = <String>{};
        while (userInterests.length < 3) {
          userInterests.add(_interests[_random.nextInt(_interests.length)]);
        }

        final email = json['email'] as String;

        return User(
          id: id,
          email: email,
          firstName: firstName,
          lastName: lastName,
          age: age,
          city: 'Remote',
          country: 'Reqres',
          gender: _random.nextBool() ? 'female' : 'male',
          bio: bio,
          imageUrl: avatar,
          interests: userInterests.toList(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Reqres API fetch error: $e');
      return [];
    }
  }
}
