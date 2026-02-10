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

        if (results.isEmpty) {
          developer.log('API returned empty results, using fallback.');
          return _getFallbackUsers(gender: gender);
        }

        return results.map((json) => User.fromJson(json)).toList();
      } else {
        developer.log('Failed to load users: ${response.statusCode}');
        return _getFallbackUsers(gender: gender);
      }
    } catch (e) {
      developer.log('Error fetching users: $e');
      return _getFallbackUsers(gender: gender);
    }
  }

  List<User> _getFallbackUsers({String? gender}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Basic mock data with unique IDs (using timestamp + index)
    final List<User> allMockUsers = [
      User(
        id: 'mock_${timestamp}_1',
        email: 'sophia.chen@example.com',
        firstName: 'Sophia',
        lastName: 'Chen',
        age: 24,
        city: 'San Francisco',
        country: 'USA',
        imageUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
        gender: 'female',
        interests: ['Art', 'Design', 'Travel', 'Coffee'],
      ),
      User(
        id: 'mock_${timestamp}_2',
        email: 'james.wilson@example.com',
        firstName: 'James',
        lastName: 'Wilson',
        age: 28,
        city: 'London',
        country: 'UK',
        imageUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
        gender: 'male',
        interests: ['Football', 'Pubs', 'Music', 'Tech'],
      ),
      User(
        id: 'mock_${timestamp}_3',
        email: 'lucas.silva@example.com',
        firstName: 'Lucas',
        lastName: 'Silva',
        age: 26,
        city: 'Rio de Janeiro',
        country: 'Brazil',
        imageUrl: 'https://randomuser.me/api/portraits/men/11.jpg',
        gender: 'male',
        interests: ['Surfing', 'Carnival', 'Food', 'Dance'],
      ),
      User(
        id: 'mock_${timestamp}_4',
        email: 'emma.jones@example.com',
        firstName: 'Emma',
        lastName: 'Jones',
        age: 25,
        city: 'Sydney',
        country: 'Australia',
        imageUrl: 'https://randomuser.me/api/portraits/women/65.jpg',
        gender: 'female',
        interests: ['Beaches', 'Hiking', 'Photography', 'Animals'],
      ),
      User(
        id: 'mock_${timestamp}_5',
        email: 'oliver.smith@example.com',
        firstName: 'Oliver',
        lastName: 'Smith',
        age: 30,
        city: 'Toronto',
        country: 'Canada',
        imageUrl: 'https://randomuser.me/api/portraits/men/86.jpg',
        gender: 'male',
        interests: ['Hockey', 'Nature', 'Beer', 'Gaming'],
      ),
      // Adding 5 more users to increase variety
      User(
        id: 'mock_${timestamp}_6',
        email: 'isabella.martinez@example.com',
        firstName: 'Isabella',
        lastName: 'Martinez',
        age: 27,
        city: 'Madrid',
        country: 'Spain',
        imageUrl: 'https://randomuser.me/api/portraits/women/33.jpg',
        gender: 'female',
        interests: ['Dancing', 'Food', 'Cinema', 'Wine'],
      ),
      User(
        id: 'mock_${timestamp}_7',
        email: 'william.brown@example.com',
        firstName: 'William',
        lastName: 'Brown',
        age: 29,
        city: 'Berlin',
        country: 'Germany',
        imageUrl: 'https://randomuser.me/api/portraits/men/54.jpg',
        gender: 'male',
        interests: ['Engineering', 'Cars', 'Beer', 'Travel'],
      ),
      User(
        id: 'mock_${timestamp}_8',
        email: 'ava.williams@example.com',
        firstName: 'Ava',
        lastName: 'Williams',
        age: 23,
        city: 'New York',
        country: 'USA',
        imageUrl: 'https://randomuser.me/api/portraits/women/12.jpg',
        gender: 'female',
        interests: ['Music', 'Concerts', 'Fashion', 'Sushi'],
      ),
      User(
        id: 'mock_${timestamp}_9',
        email: 'ethan.davis@example.com',
        firstName: 'Ethan',
        lastName: 'Davis',
        age: 31,
        city: 'Chicago',
        country: 'USA',
        imageUrl: 'https://randomuser.me/api/portraits/men/22.jpg',
        gender: 'male',
        interests: ['Basketball', 'Fitness', 'Cooking', 'Dogs'],
      ),
      User(
        id: 'mock_${timestamp}_10',
        email: 'mia.garcia@example.com',
        firstName: 'Mia',
        lastName: 'Garcia',
        age: 26,
        city: 'Barcelona',
        country: 'Spain',
        imageUrl: 'https://randomuser.me/api/portraits/women/90.jpg',
        gender: 'female',
        interests: ['Art', 'Museums', 'Reading', 'Cats'],
      ),
    ];

    List<User> filtered = allMockUsers;
    if (gender != null && gender != 'everyone') {
      filtered = allMockUsers.where((u) => u.gender == gender).toList();
    }

    // Shuffle ensuring some randomness even with small set
    filtered.shuffle();
    return filtered;
  }
}
