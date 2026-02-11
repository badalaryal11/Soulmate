import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'dart:developer' as developer;

class ApiService {
  static const String _baseUrl = 'https://randomuser.me/api/';

  Future<List<User>> fetchUsers({int results = 50, String? gender}) async {
    try {
      String url = '$_baseUrl?results=$results';
      if (gender != null) {
        url += '&gender=$gender';
      }

      developer.log('Fetching users from: $url');
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        if (results.isEmpty) {
          developer.log('API returned empty results.');
          return [];
        }

        developer.log('Successfully fetched ${results.length} users from API.');
        return results.map((json) => User.fromJson(json)).toList();
      } else {
        developer.log(
          'Failed to load users: ${response.statusCode} - ${response.reasonPhrase}',
        );
        return [];
      }
    } catch (e) {
      developer.log('Error fetching users from API: $e');
      return [];
    }
  }
}
