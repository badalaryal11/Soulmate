import '../../domain/entities/user_model.dart' as domain;
import '../../domain/repositories/user_repository.dart';
import '../datasources/database_service.dart';

class UserRepositoryImpl implements UserRepository {
  final DatabaseService _databaseService;

  UserRepositoryImpl(this._databaseService);

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
  }) {
    return _databaseService.getUsers(
      gender: gender,
      currentUserId: currentUserId,
      limit: limit,
    );
  }

  @override
  Future<void> updateUserField(String uid, Map<String, dynamic> data) {
    return _databaseService.updateUserField(uid, data);
  }
}
