import '../../domain/entities/user.dart' as domain;
import '../../domain/repositories/user_repository.dart';
import '../datasources/database_service.dart';
import '../datasources/api_service.dart';
import '../../core/error/failures.dart';
import '../../core/error/exceptions.dart';

class UserRepositoryImpl implements UserRepository {
  final DatabaseService _databaseService;
  final ApiService _apiService;

  UserRepositoryImpl(this._databaseService, this._apiService);

  @override
  Future<void> saveUser(domain.User user) async {
    try {
      await _databaseService.saveUser(user);
    } on Exception catch (e) {
      if (e is ServerException ||
          e is CacheException ||
          e is NetworkException) {
        throw ServerFailure(e.toString());
      }
      throw ServerFailure(e.toString());
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<domain.User?> getUser(String uid) async {
    try {
      return await _databaseService.getUser(uid);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<List<domain.User>> getUsers({
    String? gender,
    String? currentUserId,
    int limit = 10,
    bool refresh = false,
  }) async {
    try {
      // Fetch from Firestore and API concurrently
      final results = await Future.wait([
        _databaseService.getUsers(
          gender: gender,
          currentUserId: currentUserId,
          limit: limit,
          refresh: refresh,
        ),
        _apiService.fetchUsers(results: limit, gender: gender),
      ]);

      final firestoreUsers = results[0];
      final apiUsers = results[1];

      // Combine and deduplicate by user ID (Firestore users take priority)
      final seenIds = <String>{};
      final allUsers = <domain.User>[];
      for (final user in [...firestoreUsers, ...apiUsers]) {
        if (seenIds.add(user.id)) {
          allUsers.add(user);
        }
      }

      // Shuffle mixed results
      allUsers.shuffle();

      return allUsers;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updateUserField(String uid, Map<String, dynamic> data) async {
    try {
      await _databaseService.updateUserField(uid, data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> saveFeedback(String userId, String message) async {
    try {
      await _databaseService.saveFeedback(userId, message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<String> uploadProfileImage(String userId, dynamic imageFile) async {
    try {
      return await _databaseService.uploadProfileImage(userId, imageFile);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
