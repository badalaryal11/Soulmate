import '../entities/user_model.dart';

abstract class UserRepository {
  Future<void> saveUser(User user);
  Future<User?> getUser(String uid);
  Future<List<User>> getUsers({
    String? gender,
    String? currentUserId,
    int limit = 10,
  });
  Future<void> updateUserField(String uid, Map<String, dynamic> data);
}
