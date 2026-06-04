import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static FirebaseAuth? _mockAuth;
  static GoogleSignIn? _mockGoogleSignIn;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? _mockAuth ?? FirebaseAuth.instance,
      _googleSignIn =
          googleSignIn ??
          _mockGoogleSignIn ??
          GoogleSignIn(
            serverClientId:
                '182120669929-guh82nbc5e803t4t4sj5psecgvl3e7bd.apps.googleusercontent.com',
          );

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
        // Mobile handling
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          return null; // The user canceled the sign-in
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } catch (e, stackTrace) {
      debugPrint("Error signing in with Google: $e");
      debugPrint("Stack trace: $stackTrace");
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
        actionCodeSettings: ActionCodeSettings(
          url:
              'https://soulmate.page.link/reset-password', // Placeholder, creates link
          handleCodeInApp: true,
          iOSBundleId: 'com.badalaryal.soulmate',
          androidPackageName: 'com.badalaryal.soulmate',
          androidInstallApp: true,
          androidMinimumVersion: "1",
        ),
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
