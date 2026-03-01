import 'package:firebase_auth/firebase_auth.dart';

/// Abstract interface for authentication operations.
///
/// The presentation layer depends on this abstraction, never on
/// the concrete [AuthService] in the data layer.
abstract class AuthRepository {
  /// The currently signed-in Firebase user, or null.
  User? get currentUser;

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges;

  /// Sign in with Google. Returns null if cancelled.
  Future<UserCredential?> signInWithGoogle();

  /// Sign in with Apple. Returns null if cancelled.
  Future<UserCredential?> signInWithApple();

  /// Sign in with email and password.
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  );

  /// Register with email and password.
  Future<UserCredential?> registerWithEmailAndPassword(
    String email,
    String password,
  );

  /// Send password reset email.
  Future<void> sendPasswordResetEmail(String email);

  /// Confirm password reset with OOB code.
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  });

  /// Update the current user's email.
  Future<void> updateEmail(String newEmail);

  /// Update the current user's password.
  Future<void> updatePassword(String newPassword);

  /// Delete the current user's account.
  Future<void> deleteAccount();

  /// Sign out and clear local secure storage.
  Future<void> signOut();
}
