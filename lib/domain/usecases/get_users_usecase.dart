import '../entities/user.dart';
import '../repositories/user_repository.dart';

class GetUsersUseCase {
  final UserRepository repository;

  GetUsersUseCase(this.repository);

  Future<List<User>> call({
    String? gender,
    String? currentUserId,
    int limit = 10,
    String? lastUserId,
  }) {
    return repository.getUsers(
      gender: gender,
      currentUserId: currentUserId,
      limit: limit,
      lastUserId: lastUserId,
    );
  }
}
