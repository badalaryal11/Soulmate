import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:credential_manager/credential_manager.dart' hide User;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {


  static const String _appleProviderId = 'apple.com';
  static const String _errorNoCurrentUserCode = 'no-current-user';
  static const String _errorNoCurrentUMsg = 'No user is currently signed in.';
  static const String _errorReauthFailedCode = 'reauthentication-failed';
  static const String _errorReauthFailedMsg =
      'Google re-authentication failed or was cancelled.';
  static const String _errorEmailNotVerifiedCode = 'email-not-verified';
  static const String _errorEmailNotVerifiedMsg =
      'Please verify your email address before signing in.';
  static const String _errorCredManagerNotInitCode =
      'CREDENTIAL_MANAGER_NOT_INITIALIZED';
  static const String _errorCredManagerNotInitMsg =
      'Credential Manager is not supported or initialized on this device.';

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FlutterSecureStorage _secureStorage;
  final CredentialManager _credentialManager = CredentialManager();
  bool _isCredentialManagerInitialized = false;
  final Completer<void> _initCompleter = Completer<void>();

  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    FlutterSecureStorage? secureStorage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
       _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    try {
      final clientId = dotenv.env['GOOGLE_CLIENT_ID'];
      if (clientId != null && clientId.isNotEmpty) {
        await _googleSignIn.initialize(serverClientId: clientId);
      }
    } catch (e) {
      if (kDebugMode) debugPrint("GoogleSignIn.initialize error: $e");
    }

    // Credential Manager initialization happens here.
    await _initCredentialManager();
    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
  }

  Future<void> _initCredentialManager() async {
    try {
      if (_credentialManager.isSupportedPlatform) {
        final clientId = dotenv.env['GOOGLE_CLIENT_ID'];
        if (clientId == null || clientId.isEmpty) {
          if (kDebugMode) debugPrint("WARNING: GOOGLE_CLIENT_ID is missing from .env file. Credential Manager might fail.");
        }
        await _credentialManager.init(
          preferImmediatelyAvailableCredentials: true,
          googleClientId: clientId ?? '',
        );
        _isCredentialManagerInitialized = true;
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Failed to initialize CredentialManager: $e");
    }
  }



  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web handling
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(authProvider);
      } else {
        // Android / iOS fallback to standard google_sign_in package
        // This is necessary because getCredentials() fails if the user has no saved credentials.
        // google_sign_in handles showing the account picker UI natively.
        final googleUser = await _googleSignIn.authenticate();

        final googleAuth = googleUser.authentication;

        if (kDebugMode) {
          debugPrint(
          "Google auth idToken present: ${googleAuth.idToken != null}",
        );
        }

        if (googleAuth.idToken == null) {
          if (kDebugMode) debugPrint("Google Sign-In returned no idToken — aborting.");
          return null;
        }

        final OAuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } on PlatformException catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
        "PlatformException signing in with Google: ${e.code} - ${e.message}",
      );
      }
      if (kDebugMode) debugPrint("Stack trace: $stackTrace");
      // Error code 10 / 16 = SHA fingerprint mismatch (common in Play Store builds)
      if (e.code == '10' || e.code == '16' || e.code == 'DEVELOPER_ERROR') {
        Error.throwWithStackTrace(
          PlatformException(
            code: e.code,
            message:
                'Google Sign-In configuration error. '
                'This is likely a SHA-1 fingerprint mismatch between the app signing key '
                'and the Firebase project. Please add the Google Play App Signing SHA-1 '
                'to your Firebase project settings.',
            details: e.details,
          ),
          stackTrace,
        );
      }
      Error.throwWithStackTrace(
        PlatformException(
          code: e.code,
          message: 'Google Sign-In failed. Please try again later.',
          details: e.details,
        ),
        stackTrace,
      );
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint(
        "FirebaseAuthException during Google Sign-In: ${e.code} - ${e.message}",
      );
      }
      rethrow;
    } catch (e, stackTrace) {
      if (kDebugMode) debugPrint("Error signing in with Google: $e");
      if (kDebugMode) debugPrint("Stack trace: $stackTrace");
      // Check type properly to survive AOT minification
      if (e is GoogleSignInException &&
          e.code == GoogleSignInExceptionCode.canceled) {
        return null; // User cancelled
      }
      if (e is CredentialException ||
          e.toString().contains('CredentialException')) {
        return null; // User cancelled
      }
      rethrow;
    }
  }

  // Sign in with Apple
  Future<UserCredential?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider(_appleProviderId).credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // Apple only provides name on first sign-in, so update profile if available
      if (appleCredential.givenName != null) {
        await userCredential.user?.updateDisplayName(
          '${appleCredential.givenName} ${appleCredential.familyName ?? ''}'
              .trim(),
        );
      } else if (userCredential.user?.displayName == null || userCredential.user!.displayName!.isEmpty) {
        // Fallback to the email prefix if no name was provided and the display name is currently empty.
        final email = userCredential.user?.email ?? '';
        if (email.isNotEmpty) {
          final fallbackName = email.split('@').first;
          await userCredential.user?.updateDisplayName(fallbackName);
        }
      }

      return userCredential;
    } catch (e, stackTrace) {
      if (kDebugMode) debugPrint("Error signing in with Apple: $e");
      if (kDebugMode) debugPrint("Stack trace: $stackTrace");
      return null;
    }
  }

  // Sign In with Email and Password
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Enforce email verification
      if (credential.user != null && !credential.user!.emailVerified) {
        // Sign them back out immediately
        await _auth.signOut();
        throw FirebaseAuthException(
          code: _errorEmailNotVerifiedCode,
          message: _errorEmailNotVerifiedMsg,
        );
      }

      return credential;
    } catch (e) {
      if (kDebugMode) debugPrint("Error signing in with email and password: $e");
      rethrow;
    }
  }

  // Sign in using unified Credential Manager UI (One-Tap / Passwords / Google)
  Future<UserCredential?> signInWithCredentialManager() async {
    await _initCompleter.future;

    if (!_isCredentialManagerInitialized) {
      // Fallback if not supported
      throw PlatformException(
        code: _errorCredManagerNotInitCode,
        message: _errorCredManagerNotInitMsg,
      );
    }

    try {
      final credential = await _credentialManager.getCredentials();

      // Check credential type properly without relying on string representation which fails in AOT
      if (credential is PasswordCredential) {
        // dynamic cast is used as a workaround because some versions of the
        // credential_manager package don't statically expose the username getter.
        final email = (credential as dynamic).username as String;
        final password = (credential as dynamic).password as String;
        return await signInWithEmailAndPassword(email, password);
      } else if (credential is GoogleIdTokenCredential) {
        final idToken = (credential as dynamic).idToken as String;
        final OAuthCredential firebaseCredential =
            GoogleAuthProvider.credential(idToken: idToken);
        return await _auth.signInWithCredential(firebaseCredential);
      } else {
        if (kDebugMode) debugPrint("Unknown credential type: ${credential.runtimeType}");
      }

      return null;
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint("Credential Manager Sign-In Error: ${e.message}");
      rethrow;
    } catch (e) {
      if (kDebugMode) debugPrint("Error signing in with Credential Manager: $e");
      // Check type properly to survive AOT minification
      if (e is CredentialException ||
          e.toString().contains('CredentialException')) {
        // This usually means the user cancelled the dialog or no credentials exist
        if (kDebugMode) debugPrint("CredentialException details: ${(e as dynamic).message}");
        return null;
      }
      rethrow;
    }
  }

  // Register with Email and Password
  Future<UserCredential?> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Automatically send verification email on registration
      if (credential.user != null && !credential.user!.emailVerified) {
        await credential.user!.sendEmailVerification();
      }

      await _initCompleter.future;

      // Save credential via Credential Manager
      if (_isCredentialManagerInitialized) {
        try {
          await _credentialManager.savePasswordCredentials(
            PasswordCredential(username: email, password: password),
          );
        } catch (e) {
          if (kDebugMode) debugPrint("Failed to save password credential: $e");
        }
      }

      return credential;
    } catch (e) {
      if (kDebugMode) debugPrint("Error registering with email and password: $e");
      rethrow;
    }
  }

  // Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      if (kDebugMode) debugPrint("Error sending password reset email: $e");
      rethrow;
    }
  }

  // Update Email
  Future<void> updateEmail(String newEmail) async {
    try {
      await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail);
    } catch (e) {
      if (kDebugMode) debugPrint("Error updating email: $e");
      rethrow;
    }
  }

  // Update Password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } catch (e) {
      if (kDebugMode) debugPrint("Error updating password: $e");
      rethrow;
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } catch (e) {
      if (kDebugMode) debugPrint("Error deleting account: $e");
      rethrow;
    }
  }

  // Confirm Password Reset
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    try {
      await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
    } catch (e) {
      if (kDebugMode) debugPrint("Error confirming password reset: $e");
      rethrow;
    }
  }

  // Re-authenticate with password
  Future<void> reauthenticateWithPassword(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw FirebaseAuthException(
          code: _errorNoCurrentUserCode,
          message: _errorNoCurrentUMsg,
        );
      }
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    } catch (e) {
      if (kDebugMode) debugPrint("Error re-authenticating with password: $e");
      rethrow;
    }
  }

  // Re-authenticate with Google
  Future<void> reauthenticateWithGoogle() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: _errorNoCurrentUserCode,
          message: _errorNoCurrentUMsg,
        );
      }
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw FirebaseAuthException(
          code: _errorReauthFailedCode,
          message: _errorReauthFailedMsg,
        );
      }
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      await user.reauthenticateWithCredential(credential);
    } catch (e) {
      if (kDebugMode) debugPrint("Error re-authenticating with Google: $e");
      if (e is GoogleSignInException &&
          e.code == GoogleSignInExceptionCode.canceled) {
        return; // User cancelled
      }
      if (e is CredentialException ||
          e.toString().contains('CredentialException')) {
        return; // User cancelled
      }
      rethrow;
    }
  }

  // Re-authenticate with Apple
  Future<void> reauthenticateWithApple() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: _errorNoCurrentUserCode,
          message: _errorNoCurrentUMsg,
        );
      }
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final credential = OAuthProvider(_appleProviderId).credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      await user.reauthenticateWithCredential(credential);
    } catch (e) {
      if (kDebugMode) debugPrint("Error re-authenticating with Apple: $e");
      if (e is SignInWithAppleAuthorizationException &&
          e.code == AuthorizationErrorCode.canceled) {
        return; // User cancelled
      }
      if (e.toString().contains('canceled')) {
        return; // Fallback for cancellation
      }
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    // Securely wipe all local cached data (AES encrypted chats)
    try {
      final allKeys = await _secureStorage.readAll();
      for (final key in allKeys.keys) {
        if (key.startsWith('chat_')) {
          await _secureStorage.delete(key: key);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Error clearing secure storage during signOut: $e");
    }

    // Clear local chat/message cache from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chats_metadata');
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('chat_messages_')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Error clearing chat cache during signOut: $e");
    }

    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
