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
      // Fetch from Firestore
      final firestoreUsers = await _databaseService.getUsers(
        gender: gender,
        currentUserId: currentUserId,
        limit: limit,
        refresh: refresh,
      );

      final allUsers = List<domain.User>.from(firestoreUsers);

      // If Firestore doesn't have enough users, fetch the remainder from API
      if (allUsers.length < limit) {
        final needed = limit - allUsers.length;
        final apiUsers = await _apiService.fetchUsers(results: needed, gender: gender);
        allUsers.addAll(apiUsers);
      }

      // Shuffle results
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
