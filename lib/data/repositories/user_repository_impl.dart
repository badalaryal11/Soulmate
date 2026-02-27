import '../../domain/entities/user_model.dart' as domain;
import '../../domain/repositories/user_repository.dart';
import '../datasources/database_service.dart';
import '../datasources/api_service.dart';

class UserRepositoryImpl implements UserRepository {
  final DatabaseService _databaseService;
  final ApiService _apiService;

  UserRepositoryImpl(this._databaseService, this._apiService);

  @override
  Future<void> saveUser(domain.User user) {
    return _databaseService.saveUser(user);
  }

  @override
  Future<domain.User?> getUser(String uid) {
    return _databaseService.getUser(uid);
  }

  @override
  Future<List<domain.User>> getUsers({
    String? gender,
    String? currentUserId,
    int limit = 10,
  }) async {
    // 1. Fetch from Firestore (Real Users)
    final firestoreUsers = await _databaseService.getUsers(
      gender: gender,
      currentUserId: currentUserId,
    );

    // 2. Fetch from API (Random Users + DummyJSON)
    final apiUsers = await _apiService.fetchUsers(
      results: limit > 100 ? limit : 100,
      gender: gender,
    );

    // 3. Combine (Prioritize Firestore)
    final allUsers = [...firestoreUsers, ...apiUsers];

    // 4. Shuffle mixed results
    allUsers.shuffle();

    return allUsers;
  }

  @override
  Future<void> updateUserField(String uid, Map<String, dynamic> data) {
    return _databaseService.updateUserField(uid, data);
  }
}
