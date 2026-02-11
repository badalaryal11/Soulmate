import 'package:soulmate/data/models/user_model.dart';
import 'package:soulmate/data/services/api_service.dart';
import 'package:soulmate/data/services/database_service.dart';

class UserRepository {
  final ApiService _apiService;
  final DatabaseService _databaseService;

  UserRepository({ApiService? apiService, DatabaseService? databaseService})
    : _apiService = apiService ?? ApiService(),
      _databaseService = databaseService ?? DatabaseService();

  Future<List<User>> getUsers({String? gender, String? currentUserId}) async {
    // 1. Fetch from Firestore (Real Users)
    final firestoreUsers = await _databaseService.getUsers(
      gender: gender,
      currentUserId: currentUserId,
    );

    // 2. Fetch from API (Mock/Random Users)
    final apiUsers = await _apiService.fetchUsers(gender: gender);

    // 3. Combine (Prioritize Firestore)
    // You might want to remove duplicates if any, but IDs should differ (Firestore vs UUIDs)
    return [...firestoreUsers, ...apiUsers];
  }
}
