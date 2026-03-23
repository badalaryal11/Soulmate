import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/user.dart';

/// Fetches random user profiles from randomuser.me to supplement
/// the Firestore user pool in the discovery deck.
/// Falls back to locally generated profiles if the API is down.
class RandomUserApiService {
  static const String _baseUrl = 'https://randomuser.me/api/';
  static final _random = Random();
  static int _fallbackCounter = 0;
  
  static final http.Client _client = http.Client();
  static final List<User> _userCache = [];
  static String? _lastRequestedGender;
  static bool _isFetching = false;

  static const List<String> _defaultInterests = [
    'Travel', 'Music', 'Photography', 'Cooking', 'Reading',
    'Fitness', 'Movies', 'Art', 'Dancing', 'Hiking',
    'Gaming', 'Yoga', 'Coffee', 'Nature', 'Sports',
  ];

  static const List<String> _bios = [
    'Living life one adventure at a time ✨',
    'Coffee lover, sunset chaser, and dog person 🐕',
    'Here for genuine connections, not games 💫',
    'Foodie who loves trying new restaurants 🍕',
    'Gym enthusiast and early morning runner 🏃',
    'Bookworm with a passion for travel 📚✈️',
    'Music is my therapy 🎵',
    'Looking for my partner in crime 😊',
    'Love hiking and outdoor adventures 🏔️',
    'Creative soul with a sense of humor 🎨',
  ];

  static const List<String> _maleNames = [
    'James', 'William', 'Oliver', 'Benjamin', 'Lucas',
    'Henry', 'Alexander', 'Sebastian', 'Daniel', 'Matthew',
    'Ethan', 'Noah', 'Liam', 'Mason', 'Logan',
    'Jackson', 'Aiden', 'Samuel', 'David', 'Joseph',
  ];

  static const List<String> _femaleNames = [
    'Emma', 'Olivia', 'Ava', 'Sophia', 'Isabella',
    'Mia', 'Charlotte', 'Amelia', 'Harper', 'Evelyn',
    'Aria', 'Luna', 'Chloe', 'Penelope', 'Layla',
    'Riley', 'Zoey', 'Nora', 'Lily', 'Eleanor',
  ];

  static const List<String> _lastNames = [
    'Smith', 'Johnson', 'Williams', 'Brown', 'Jones',
    'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez',
    'Wilson', 'Anderson', 'Taylor', 'Thomas', 'Moore',
    'Jackson', 'Martin', 'Lee', 'Thompson', 'White',
  ];

  static const List<String> _cities = [
    'New York', 'Los Angeles', 'Chicago', 'Houston', 'London',
    'Toronto', 'Sydney', 'Melbourne', 'Vancouver', 'Austin',
    'Denver', 'Portland', 'Seattle', 'Boston', 'Miami',
  ];

  static const List<String> _countries = [
    'United States', 'United States', 'United States', 'United States',
    'United Kingdom', 'Canada', 'Australia', 'Australia', 'Canada',
    'United States', 'United States', 'United States', 'United States',
    'United States', 'United States',
  ];

  /// Fetch [count] random users, optionally filtered by [gender].
  /// Falls back to locally generated profiles if the API is unreachable.
  static Future<List<User>> fetchRandomUsers({
    int count = 20,
    String? gender,
  }) async {
    // Clear cache if the user switched their gender preference
    if (_lastRequestedGender != gender) {
      _userCache.clear();
      _lastRequestedGender = gender;
    }

    // Cache Hit
    if (_userCache.length >= count) {
      final users = _userCache.sublist(0, count);
      _userCache.removeRange(0, count);
      
      // Fire and forget background refill to ensure next batch is ready
      _refillCacheInBackground(count: count * 2, gender: gender);
      return users;
    }

    // Cache Miss: fetch directly
    _isFetching = true;
    final apiUsers = await _fetchFromApi(count: count, gender: gender);
    _isFetching = false;

    if (apiUsers.isNotEmpty) {
      return apiUsers;
    }

    // Fallback: generate profiles locally
    debugPrint('RandomUser API unavailable — using local fallback');
    return _generateLocalUsers(count: count, gender: gender);
  }

  static Future<void> _refillCacheInBackground({
    required int count,
    String? gender,
  }) async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      final newUsers = await _fetchFromApi(count: count, gender: gender);
      // Ensure the user hasn't toggled gender while we were waiting
      if (_lastRequestedGender == gender && newUsers.isNotEmpty) {
        _userCache.addAll(newUsers);
      }
    } finally {
      _isFetching = false;
    }
  }

  static Future<List<User>> _fetchFromApi({
    required int count,
    String? gender,
  }) async {
    try {
      final queryParams = <String, String>{
        'results': count.toString(),
        'nat': 'us,gb,ca,au',
        'inc': 'name,location,email,picture,dob,gender,login',
      };

      if (gender != null && gender.toLowerCase() != 'everyone') {
        queryParams['gender'] = gender.toLowerCase();
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      final response = await _client.get(uri).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode != 200) {
        debugPrint('RandomUser API error: ${response.statusCode}');
        return [];
      }

      final data = json.decode(response.body);
      final results = data['results'] as List<dynamic>;

      return results.map<User>((json) => _mapToUser(json)).toList();
    } catch (e) {
      debugPrint('RandomUser API fetch error: $e');
      return [];
    }
  }

  static List<User> _generateLocalUsers({
    required int count,
    String? gender,
  }) {
    final users = <User>[];
    final genderLower = gender?.toLowerCase();

    for (int i = 0; i < count; i++) {
      final isMale = genderLower == 'male'
          ? true
          : genderLower == 'female'
              ? false
              : _random.nextBool();

      final firstName = isMale
          ? _maleNames[_random.nextInt(_maleNames.length)]
          : _femaleNames[_random.nextInt(_femaleNames.length)];
      final lastName = _lastNames[_random.nextInt(_lastNames.length)];
      final cityIndex = _random.nextInt(_cities.length);
      final age = 20 + _random.nextInt(15);

      // Use ui-avatars.com for fallback profile images (always available, no API key)
      final avatarUrl = 'https://ui-avatars.com/api/'
          '?name=${Uri.encodeComponent('$firstName $lastName')}'
          '&size=400&background=random&color=fff&bold=true&format=png';

      final shuffled = List<String>.from(_defaultInterests)..shuffle(_random);
      final interests = shuffled.take(2 + _random.nextInt(3)).toList();

      _fallbackCounter++;
      users.add(User(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}_$_fallbackCounter',
        email: '${firstName.toLowerCase()}.${lastName.toLowerCase()}@example.com',
        firstName: firstName,
        lastName: lastName,
        age: age,
        city: _cities[cityIndex],
        country: _countries[cityIndex],
        imageUrl: avatarUrl,
        gender: isMale ? 'male' : 'female',
        interests: interests,
        bio: _bios[_random.nextInt(_bios.length)],
      ));
    }

    return users;
  }

  static User _mapToUser(Map<String, dynamic> json) {
    final name = json['name'] as Map<String, dynamic>;
    final location = json['location'] as Map<String, dynamic>;
    final dob = json['dob'] as Map<String, dynamic>;
    final picture = json['picture'] as Map<String, dynamic>;
    final login = json['login'] as Map<String, dynamic>;

    final shuffled = List<String>.from(_defaultInterests)..shuffle(_random);
    final interests = shuffled.take(2 + _random.nextInt(3)).toList();

    return User(
      id: 'api_${login['uuid']}',
      email: json['email'] ?? '',
      firstName: name['first'] ?? '',
      lastName: name['last'] ?? '',
      age: dob['age'] ?? (20 + _random.nextInt(15)),
      city: location['city'] ?? '',
      country: location['country'] ?? '',
      imageUrl: picture['large'] ?? '',
      gender: json['gender'] ?? 'other',
      interests: interests,
      bio: _bios[_random.nextInt(_bios.length)],
    );
  }
}
