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
  static String? _lastRequestedGender;
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
    // Clear cache if the user switched their gender preference
    if (_lastRequestedGender != gender) {
      _userCache.clear();
      _lastRequestedGender = gender;
    }

    if (_userCache.length >= count) {
      final users = _userCache.sublist(0, count);
      _userCache.removeRange(0, count);
      _refillCacheInBackground(gender: gender);
      return users;
    }

    _isFetching = true;
    try {
      final apiUsers = await _fetchFromApi(gender: gender);
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

  static Future<void> _refillCacheInBackground({String? gender}) async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      final newUsers = await _fetchFromApi(gender: gender);
      if (_lastRequestedGender == gender && newUsers.isNotEmpty) {
        _userCache.addAll(newUsers);
      }
    } finally {
      _isFetching = false;
    }
  }

  static Future<List<User>> _fetchFromApi({String? gender}) async {
    try {
      // Fetch all 12 users so we can filter and cache them reliably
      final uri = Uri.parse('$_baseUrl?per_page=12');
      final response = await _client.get(uri).timeout(const Duration(seconds: 2));

      if (response.statusCode != 200) {
        return [];
      }

      final data = json.decode(response.body);
      final usersJson = data['data'] as List<dynamic>?;
      if (usersJson == null) return [];

      final allUsers = usersJson.map<User>((json) {
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
        final idNum = json['id'] as int;

        // ReqRes static users mapping:
        // Males: George(1), Charles(5), Michael(7), Tobias(9), Byron(10), George(11)
        // Females: Janet(2), Emma(3), Eve(4), Tracey(6), Lindsay(8), Rachel(12)
        final isMale = [1, 5, 7, 9, 10, 11].contains(idNum);
        final genderStr = isMale ? 'male' : 'female';

        return User(
          id: id,
          email: email,
          firstName: firstName,
          lastName: lastName,
          age: age,
          city: 'Remote',
          country: 'Reqres',
          gender: genderStr,
          bio: bio,
          imageUrl: avatar,
          interests: userInterests.toList(),
        );
      }).toList();

      // Shuffle so they don't always appear in numerical ID order
      allUsers.shuffle();

      // Filter by gender if requested
      if (gender != null && gender.toLowerCase() != 'everyone') {
        final targetGender = gender.toLowerCase();
        return allUsers.where((u) => u.gender == targetGender).toList();
      }

      return allUsers;
    } catch (e) {
      debugPrint('Reqres API fetch error: $e');
      return [];
    }
  }
}
