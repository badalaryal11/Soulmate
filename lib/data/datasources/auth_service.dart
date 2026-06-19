import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:credential_manager/credential_manager.dart' hide User;

class AuthService {
  static FirebaseAuth? _mockAuth;
  static GoogleSignIn? _mockGoogleSignIn;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final CredentialManager _credentialManager = CredentialManager();
  bool _isCredentialManagerInitialized = false;

  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? _mockAuth ?? FirebaseAuth.instance,
      _googleSignIn =
          googleSignIn ??
          _mockGoogleSignIn ??
          GoogleSignIn.instance {
    _initAuth();
  }

  Future<void> _initAuth() async {
    // GoogleSignIn.instance.initialize() is already called in main.dart.
    // Calling it a second time on google_sign_in v7 can cause undefined
    // behavior and silently break the authenticate() flow.
    await _initCredentialManager();
  }

  Future<void> _initCredentialManager() async {
    try {
      if (_credentialManager.isSupportedPlatform) {
        await _credentialManager.init(
          preferImmediatelyAvailableCredentials: true,
          googleClientId: '182120669929-334pgll1nu6l53kvkfl9ure8fv6ots2r.apps.googleusercontent.com',
        );
        _isCredentialManagerInitialized = true;
      }
    } catch (e) {
      debugPrint("Failed to initialize CredentialManager: $e");
    }
  }

  @visibleForTesting
  static void setMockInstances({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  }) {
    _mockAuth = auth;
    _mockGoogleSignIn = googleSignIn;
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

        debugPrint("Google auth idToken present: ${googleAuth.idToken != null}");


        if (googleAuth.idToken == null) {
          // This almost always means the app's SHA-1 signing certificate is not
          // registered in the Firebase Console. In production, Google Play
          // re-signs the app bundle so the Play App Signing SHA-1 must also be
          // added to Firebase → Project settings → Android app → SHA fingerprints.
          debugPrint("Google Sign-In returned no idToken — this typically means "
              "the SHA-1 fingerprint of the signing key is not registered in Firebase.");
          throw PlatformException(
            code: 'GOOGLE_SIGN_IN_NO_ID_TOKEN',
            message: 'Google Sign-In failed. Please try again later.',
          );
        }

        final OAuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,

        );

        return await _auth.signInWithCredential(credential);
      }
    } on PlatformException catch (e, stackTrace) {
      debugPrint("PlatformException signing in with Google: ${e.code} - ${e.message}");
      debugPrint("Stack trace: $stackTrace");
      throw PlatformException(
        code: e.code,
        message: 'Google Sign-In failed. Please try again later.',
      );
    } catch (e, stackTrace) {
      debugPrint("Error signing in with Google: $e");
      debugPrint("Stack trace: $stackTrace");
      // Check type properly to survive AOT minification
      if (e is GoogleSignInException && e.code == GoogleSignInExceptionCode.canceled) {
        return null; // User cancelled
      }
      if (e is CredentialException || e.toString().contains('CredentialException')) {
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

      final oauthCredential = OAuthProvider('apple.com').credential(
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
      }

      return userCredential;
    } catch (e, stackTrace) {
      debugPrint("Error signing in with Apple: $e");
      debugPrint("Stack trace: $stackTrace");
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
          code: 'email-not-verified',
          message: 'Please verify your email address before signing in.',
        );
      }

      return credential;
    } catch (e) {
      debugPrint("Error signing in with email and password: $e");
      rethrow;
    }
  }

  // Sign in using unified Credential Manager UI (One-Tap / Passwords / Google)
  Future<UserCredential?> signInWithCredentialManager() async {
    if (!_isCredentialManagerInitialized) {
      // Fallback if not supported
      throw PlatformException(
        code: 'CREDENTIAL_MANAGER_NOT_INITIALIZED',
        message: 'Credential Manager is not supported or initialized on this device.',
      );
    }

    try {
      final credential = await _credentialManager.getCredentials();

      // Check credential type properly without relying on string representation which fails in AOT
      if (credential is PasswordCredential) {
        final email = (credential as dynamic).username as String;
        final password = (credential as dynamic).password as String;
        return await signInWithEmailAndPassword(email, password);
      } else if (credential is GoogleIdTokenCredential) {
        final idToken = (credential as dynamic).idToken as String;
        final OAuthCredential firebaseCredential = GoogleAuthProvider.credential(
          idToken: idToken,
        );
        return await _auth.signInWithCredential(firebaseCredential);
      } else {
        debugPrint("Unknown credential type: ${credential.runtimeType}");
      }
      
      return null;
    } on PlatformException catch (e) {
      debugPrint("Credential Manager Sign-In Error: ${e.message}");
      return null;
    } catch (e) {
      debugPrint("Error signing in with Credential Manager: $e");
      // Check type properly to survive AOT minification
      if (e is CredentialException || e.toString().contains('CredentialException')) {
        // This usually means the user cancelled the dialog or no credentials exist
        debugPrint("CredentialException details: ${(e as dynamic).message}");
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

      // Save credential via Credential Manager
      if (_isCredentialManagerInitialized) {
        try {
          await _credentialManager.savePasswordCredentials(
            PasswordCredential(
              username: email,
              password: password,
            ),
          );
        } catch (e) {
          debugPrint("Failed to save password credential: $e");
        }
      }

      return credential;
    } catch (e) {
      debugPrint("Error registering with email and password: $e");
      rethrow;
    }
  }

  // Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: email,
      );
    } catch (e) {
      debugPrint("Error sending password reset email: $e");
      rethrow;
    }
  }

  // Update Email
  Future<void> updateEmail(String newEmail) async {
    try {
      await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail);
    } catch (e) {
      debugPrint("Error updating email: $e");
      rethrow;
    }
  }

  // Update Password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } catch (e) {
      debugPrint("Error updating password: $e");
      rethrow;
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } catch (e) {
      debugPrint("Error deleting account: $e");
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
      debugPrint("Error confirming password reset: $e");
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    // Securely wipe all local cached data (AES encrypted chats)
    const secureStorage = FlutterSecureStorage();
    await secureStorage.deleteAll();

    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
