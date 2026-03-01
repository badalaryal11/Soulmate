import '../repositories/auth_repository.dart';

class SendPasswordResetUseCase {
  final AuthRepository repository;

  SendPasswordResetUseCase(this.repository);

  Future<void> call(String email) {
    return repository.sendPasswordResetEmail(email);
  }
}
