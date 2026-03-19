import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/user.dart';

/// Fetches random user profiles from randomuser.me to supplement
/// the Firestore user pool in the discovery deck.
class RandomUserApiService {
  static const String _baseUrl = 'https://randomuser.me/api/';
  static final _random = Random();

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

  /// Fetch [count] random users, optionally filtered by [gender].
  /// Returns a list of [User] entities with API-prefixed IDs
  /// to distinguish them from Firestore users.
  static Future<List<User>> fetchRandomUsers({
    int count = 20,
    String? gender,
  }) async {
    try {
      final queryParams = <String, String>{
        'results': count.toString(),
        'nat': 'us,gb,ca,au',
        'inc': 'name,location,email,picture,dob,gender,login',
      };

      // Map gender filter to API format
      if (gender != null && gender.toLowerCase() != 'everyone') {
        queryParams['gender'] = gender.toLowerCase();
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri).timeout(
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

  static User _mapToUser(Map<String, dynamic> json) {
    final name = json['name'] as Map<String, dynamic>;
    final location = json['location'] as Map<String, dynamic>;
    final dob = json['dob'] as Map<String, dynamic>;
    final picture = json['picture'] as Map<String, dynamic>;
    final login = json['login'] as Map<String, dynamic>;

    // Generate 2-4 random interests
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
