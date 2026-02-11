import 'package:soulmate/data/models/user_model.dart';
import 'package:soulmate/data/services/api_service.dart';

class UserRepository {
  final ApiService _apiService;
  UserRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  Future<List<User>> getUsers({String? gender, String? currentUserId}) async {
    // 1. Fetch from Firestore (Real Users)
    // 1. Fetch from Firestore (Real Users)
    // Disabled by user request to avoid connection errors
    /*
    final firestoreUsers = await _databaseService.getUsers(
      gender: gender,
      currentUserId: currentUserId,
    );
    */

    // 2. Fetch from API (Mock/Random Users + Local Celebrity Assets)
    final apiUsers = await _apiService.fetchUsers(gender: gender);

    // 3. Combine (Prioritize Firestore)
    // You might want to remove duplicates if any, but IDs should differ (Firestore vs UUIDs)
    return [...apiUsers];
  }
}
