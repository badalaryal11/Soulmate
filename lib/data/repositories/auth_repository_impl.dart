import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_service.dart';
import '../../core/error/failures.dart';

/// Concrete implementation of [AuthRepository] backed by [AuthService].
class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;

  AuthRepositoryImpl(this._authService);

  @override
  User? get currentUser => _authService.currentUser;

  @override
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  @override
  Future<UserCredential?> signInWithGoogle() async {
    try {
      return await _authService.signInWithGoogle();
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  @override
  Future<UserCredential?> signInWithApple() async {
    try {
      return await _authService.signInWithApple();
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  @override
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _authService.signInWithEmailAndPassword(email, password);
    } catch (e) {
      rethrow; // Let FirebaseAuthException propagate for specific error handling in UI
    }
  }

  @override
  Future<UserCredential?> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _authService.registerWithEmailAndPassword(email, password);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  @override
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    try {
      await _authService.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    try {
      await _authService.updateEmail(newEmail);
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _authService.updatePassword(newPassword);
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _authService.deleteAccount();
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }
}
