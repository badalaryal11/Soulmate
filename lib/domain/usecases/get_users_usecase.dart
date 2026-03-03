import '../entities/user.dart';
import '../repositories/user_repository.dart';

class GetUsersUseCase {
  final UserRepository repository;

  GetUsersUseCase(this.repository);

  Future<List<User>> call({
    String? gender,
    String? currentUserId,
    int limit = 10,
    bool refresh = false,
  }) {
    return repository.getUsers(
      gender: gender,
      currentUserId: currentUserId,
      limit: limit,
      refresh: refresh,
    );
  }
}
