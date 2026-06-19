import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:soulmate/domain/repositories/auth_repository.dart';
import 'package:soulmate/domain/repositories/user_repository.dart';
import 'package:soulmate/domain/entities/user.dart';

class LoginProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  LoginProvider({
    required AuthRepository authRepository,
    required UserRepository userRepository,
  }) : _authRepository = authRepository,
       _userRepository = userRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  firebase_auth.User? _firebaseUser;
  firebase_auth.User? get firebaseUser => _firebaseUser;

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void clearError() => _setError(null);

  void _setLoading(bool value) {
    if (_isDisposed) return;
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    if (_isDisposed) return;
    _errorMessage = message;
    notifyListeners();
  }

  /// Returns true if the user is a new user (needs to create profile),
  /// false if the user is an existing user (can proceed to home/gender selection),
  /// and null if the login failed or was cancelled.
  Future<bool?> signInWithGoogle() async {
    _setLoading(true);
    _setError(null);
    try {
      final credential = await _authRepository.signInWithGoogle();
      if (credential != null && credential.user != null) {
        return await _handleSuccessfulAuth(credential.user!);
      } else {
        // Sign-in was cancelled or returned no tokens.
        debugPrint('Google Sign-In returned null credential.');
        return null;
      }
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Returns true if the user is a new user (needs to create profile),
  /// false if the user is an existing user (can proceed to home/gender selection),
  /// and null if the login failed or was cancelled.
  Future<bool?> signInWithCredentialManager() async {
    _setLoading(true);
    _setError(null);
    try {
      final credential = await _authRepository.signInWithCredentialManager();
      if (credential != null && credential.user != null) {
        return await _handleSuccessfulAuth(credential.user!);
      } else {
        // Sign-in was cancelled by the user or no credentials found.
        return null;
      }
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Returns true if the user is a new user, false otherwise.
  Future<bool?> signInWithApple() async {
    _setLoading(true);
    _setError(null);
    try {
      final credential = await _authRepository.signInWithApple();
      if (credential != null && credential.user != null) {
        return await _handleSuccessfulAuth(credential.user!);
      } else {
        _setError('Apple Sign-In was cancelled.');
        return null;
      }
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Returns true if the user is a new user, false otherwise.
  Future<bool?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    _setLoading(true);
    _setError(null);
    try {
      final credential = await _authRepository.signInWithEmailAndPassword(
        email,
        password,
      );
      if (credential != null && credential.user != null) {
        return await _handleSuccessfulAuth(credential.user!);
      } else {
        _setError('Login failed. Please check your credentials.');
        return null;
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
        case 'user-not-found':
          message = 'Incorrect email or password. Please try again.';
          break;
        case 'invalid-email':
          message = 'The email address is invalid.';
          break;
        case 'user-disabled':
          message = 'This user account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many unsuccessful login attempts. Please try again later.';
          break;
        default:
          message = e.message ?? 'An error occurred. Please try again.';
      }
      _setError(message);
      return null;
    } catch (e) {
      if (e.toString().contains('email-not-verified') || e.toString().contains('Please verify your email address')) {
        _setError('Please verify your email address before signing in.');
      } else {
        _setError(e.toString());
      }
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authRepository.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _handleSuccessfulAuth(firebase_auth.User firebaseUser) async {
    _firebaseUser = firebaseUser;

    // Check if user exists in Firestore
    User? existingUser = await _userRepository.getUser(firebaseUser.uid);

    if (existingUser == null) {
      // User does not exist, redirect to Create Profile
      return true; // isNewUser = true
    } else {
      // User exists, update last login date in the background without blocking login
      _userRepository.updateUserField(firebaseUser.uid, {
        'lastLoginDate': DateTime.now().toIso8601String(),
      }).catchError((e) {
        debugPrint('Failed to update last login date: $e');
      });
      return false; // isNewUser = false
    }
  }
}
