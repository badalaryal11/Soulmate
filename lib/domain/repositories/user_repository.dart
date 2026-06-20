import '../entities/user.dart';

abstract class UserRepository {
  Future<void> saveUser(User user);
  Future<User?> getUser(String uid);
  Future<List<User>> getUsers({
    String? gender,
    String? currentUserId,
    int limit = 10,
    bool refresh = false,
  });
  Future<void> updateUserField(String uid, Map<String, dynamic> data);
  Future<void> saveFeedback(String userId, String message);
  Future<String> uploadProfileImage(String userId, dynamic imageFile, {String? userName, String? email});
  Future<void> deleteUser(String uid);
}
