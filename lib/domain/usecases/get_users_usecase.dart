import '../entities/user_model.dart';
import '../repositories/user_repository.dart';

class GetUsersUseCase {
  final UserRepository repository;

  GetUsersUseCase(this.repository);

  Future<List<User>> call({
    String? gender,
    String? currentUserId,
    int limit = 10,
  }) {
    return repository.getUsers(
      gender: gender,
      currentUserId: currentUserId,
      limit: limit,
    );
  }
}
