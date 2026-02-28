import '../repositories/user_repository.dart';
import '../entities/user.dart';

class GetCurrentUserUseCase {
  final UserRepository repository;

  GetCurrentUserUseCase(this.repository);

  Future<User?> call(String uid) async {
    return await repository.getUser(uid);
  }
}
