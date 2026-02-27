import 'dart:convert';
import 'package:flutter/foundation.dart'; // For compute
import 'package:http/http.dart' as http;
import 'package:soulmate/data/models/user_model.dart';
import '../../domain/entities/user_model.dart' as domain;
import 'image_generation_service.dart';
import 'dart:developer' as developer;

// Top-level function for compute
List<domain.User> parseDummyJsonUsers(String responseBody) {
  final Map<String, dynamic> data = json.decode(responseBody);
  final List<dynamic> usersData = data['users'];
  return usersData.map((json) {
    final user = UserModel.fromDummyJson(json);
    // Replace DummyJSON image with high-quality generated one
    return user.copyWith(
      imageUrl: ImageGenerationService.generateProfileImageUrl(user),
    );
  }).toList();
}

// Top-level function for compute
List<domain.User> parseRandomUserMeUsers(String responseBody) {
  final Map<String, dynamic> data = json.decode(responseBody);
  final List<dynamic> usersData = data['results'];
  return usersData.map((json) => UserModel.fromRandomUser(json)).toList();
}

class ApiService {
  // Shared HTTP client for connection reuse
  static final http.Client _client = http.Client();

  // Base URL is kept but unused in this local-only mode
  static const String _dummyJsonUrl = 'https://dummyjson.com/users';
  static const String _randomUserUrl = 'https://randomuser.me/api/';

  Future<List<domain.User>> fetchUsers({int results = 50, String? gender}) async {
    // Split results between the two APIs
    // Ensure at least 1 user from each if results is small, otherwise split roughly 50/50
    int halfLimit = (results / 2).ceil();

    // Fetch from both sources in parallel
    final dummyJsonFuture = _fetchDummyJsonUsers(
      results: halfLimit,
      gender: gender,
    );
    final randomUserFuture = _fetchRandomUserMeUsers(
      results: halfLimit,
      gender: gender,
    );

    final resultsList = await Future.wait([dummyJsonFuture, randomUserFuture]);

    final List<domain.User> allUsers = [];
    allUsers.addAll(resultsList[0]);
    allUsers.addAll(resultsList[1]);

    // Shuffle to mix them up
    allUsers.shuffle();

    developer.log('Total users fetched and shuffled: ${allUsers.length}');
    return allUsers;
  }

  Future<List<domain.User>> _fetchDummyJsonUsers({
    required int results,
    String? gender,
  }) async {
    int attempts = 0;
    const int maxAttempts = 3;

    while (attempts < maxAttempts) {
      try {
        attempts++;
        String url = '$_dummyJsonUrl?limit=$results';
        if (gender != null && gender != 'everyone') {
          url = '$_dummyJsonUrl/filter?key=gender&value=$gender&limit=$results';
        }

        developer.log('Fetching DummyJSON users: $url');
        final response = await _client
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          // Offload parsing to background isolate
          return await compute(parseDummyJsonUsers, response.body);
        } else {
          if (response.statusCode >= 400 && response.statusCode < 500) {
            return [];
          }
        }
      } catch (e) {
        developer.log('Error fetching DummyJSON users (Attempt $attempts): $e');
        if (attempts >= maxAttempts) {
          return [];
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return [];
  }

  Future<List<domain.User>> _fetchRandomUserMeUsers({
    required int results,
    String? gender,
  }) async {
    int attempts = 0;
    const int maxAttempts = 3;

    while (attempts < maxAttempts) {
      try {
        attempts++;
        // RandomUser parameters: ?results=X&gender=male
        String url = '$_randomUserUrl?results=$results';
        if (gender != null && gender != 'everyone') {
          url += '&gender=$gender';
        }

        developer.log('Fetching RandomUser.me users: $url');
        final response = await _client
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          // Offload parsing to background isolate
          return await compute(parseRandomUserMeUsers, response.body);
        } else {
          if (response.statusCode >= 400 && response.statusCode < 500) {
            return [];
          }
        }
      } catch (e) {
        developer.log(
          'Error fetching RandomUser users (Attempt $attempts): $e',
        );
        if (attempts >= maxAttempts) {
          return [];
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return [];
  }
}
