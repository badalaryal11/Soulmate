import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'dart:developer' as developer;

class ApiService {
  static const String _baseUrl = 'https://randomuser.me/api/';

  Future<List<User>> fetchUsers({int results = 20, String? gender}) async {
    try {
      String url = '$_baseUrl?results=$results';
      if (gender != null) {
        url += '&gender=$gender';
      }
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        return results.map((json) => User.fromJson(json)).toList();
      } else {
        developer.log('Failed to load users: ${response.statusCode}');
        throw Exception('Failed to load users');
      }
    } catch (e) {
      developer.log('Error fetching users: $e');
      throw Exception('Error fetching users');
    }
  }
}
