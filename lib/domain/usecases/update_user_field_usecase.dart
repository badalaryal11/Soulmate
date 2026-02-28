import '../repositories/user_repository.dart';

class UpdateUserFieldUseCase {
  final UserRepository repository;

  UpdateUserFieldUseCase(this.repository);

  Future<void> call(String uid, Map<String, dynamic> data) async {
    return await repository.updateUserField(uid, data);
  }
}
