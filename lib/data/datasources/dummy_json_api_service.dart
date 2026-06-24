import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/user.dart';
import '../models/user_model.dart';

import '../../core/network/authenticated_http_client.dart';

class DummyJsonApiService {
  static const String _baseUrl = 'https://soulmate-gateway-2bnxy0a1.uc.gateway.dev/dummyjson/users';
  static final http.Client _client = AuthenticatedHttpClient(http.Client());
  static final List<User> _userCache = [];
  static String? _lastRequestedGender;
  static bool _isFetching = false;

  static Future<List<User>> fetchDummyUsers({
    int count = 10,
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
      
      _refillCacheInBackground(count: count * 2, gender: gender);
      return users;
    }

    // Cache Miss: fetch directly
    _isFetching = true;
    try {
      final apiUsers = await _fetchFromApi(count: count, gender: gender);
      if (apiUsers.isNotEmpty) {
        return apiUsers;
      }
    } finally {
      _isFetching = false;
    }

    return [];
  }

  static Future<void> _refillCacheInBackground({
    required int count,
    String? gender,
  }) async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      final newUsers = await _fetchFromApi(count: count, gender: gender);
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
      Uri uri;
      final isGendered = gender != null && gender.toLowerCase() != 'everyone';
      final maxSkip = isGendered ? (50 - count) : (100 - count);
      final skip = maxSkip > 0 ? (DateTime.now().millisecondsSinceEpoch % maxSkip) : 0;
      if (gender != null && gender.toLowerCase() != 'everyone') {
        uri = Uri.parse('$_baseUrl/filter?key=gender&value=${gender.toLowerCase()}&limit=$count&skip=$skip');
      } else {
        uri = Uri.parse('$_baseUrl?limit=$count&skip=$skip');
      }

      final response = await _client.get(uri).timeout(const Duration(seconds: 2));

      if (response.statusCode != 200) {
        debugPrint('DummyJSON API error: ${response.statusCode}');
        return [];
      }

      final data = json.decode(response.body);
      final usersJson = data['users'] as List<dynamic>?;
      if (usersJson == null) return [];

      return usersJson.map<User>((json) => UserModel.fromDummyJson(json)).toList();
    } catch (e) {
      debugPrint('DummyJSON API fetch error: $e');
      return [];
    }
  }
}
