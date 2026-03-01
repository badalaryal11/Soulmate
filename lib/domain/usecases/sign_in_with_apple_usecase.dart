import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';

class SignInWithAppleUseCase {
  final AuthRepository repository;

  SignInWithAppleUseCase(this.repository);

  Future<UserCredential?> call() {
    return repository.signInWithApple();
  }
}
