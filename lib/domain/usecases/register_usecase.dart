import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<UserCredential?> call(String email, String password) {
    return repository.registerWithEmailAndPassword(email, password);
  }
}
