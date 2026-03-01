import '../repositories/auth_repository.dart';

class ConfirmPasswordResetUseCase {
  final AuthRepository repository;

  ConfirmPasswordResetUseCase(this.repository);

  Future<void> call({required String code, required String newPassword}) {
    return repository.confirmPasswordReset(
      code: code,
      newPassword: newPassword,
    );
  }
}
