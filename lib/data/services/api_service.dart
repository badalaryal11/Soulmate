import 'dart:convert';
import 'package:http/http.dart' as http; // Kept to avoid breaking imports
import '../models/user_model.dart';
import 'dart:developer' as developer;

class ApiService {
  // Base URL is kept but unused in this local-only mode
  static const String _baseUrl = 'https://dummyjson.com/users';

  Future<List<User>> fetchUsers({int results = 50, String? gender}) async {
    // 1. Fetch from API (Random Users via DummyJSON)
    int attempts = 0;
    const int maxAttempts = 3;

    while (attempts < maxAttempts) {
      try {
        attempts++;
        // DummyJSON uses 'limit' instead of 'results'
        // https://dummyjson.com/users?limit=50

        String url = '$_baseUrl?limit=$results';
        if (gender != null && gender != 'everyone') {
          // DummyJSON filtering: https://dummyjson.com/users/filter?key=gender&value=male
          url = '$_baseUrl/filter?key=gender&value=$gender&limit=$results';
        }

        developer.log(
          'Fetching users from: $url (Attempt $attempts/$maxAttempts)',
        );
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          final List<dynamic> usersData = data['users'];

          if (usersData.isEmpty) {
            developer.log('API returned empty results.');
            return [];
          }

          developer.log('Successfully fetched ${usersData.length} users.');
          return usersData.map((json) => User.fromDummyJson(json)).toList();
        } else {
          developer.log(
            'Failed to load users: ${response.statusCode} - ${response.reasonPhrase}',
          );
          // Don't retry immediately on client errors (4xx), but retry on 5xx or timeout
          if (response.statusCode >= 400 && response.statusCode < 500) {
            return [];
          }
        }
      } catch (e) {
        developer.log('Error fetching users (Attempt $attempts): $e');
        if (attempts >= maxAttempts) {
          developer.log('Max retries reached. Giving up.');
          return [];
        }
        // Wait before retrying
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return [];
  }
}
