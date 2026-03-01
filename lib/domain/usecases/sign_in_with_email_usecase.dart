import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';

class SignInWithEmailUseCase {
  final AuthRepository repository;

  SignInWithEmailUseCase(this.repository);

  Future<UserCredential?> call(String email, String password) {
    return repository.signInWithEmailAndPassword(email, password);
  }
}
