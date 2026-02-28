import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:soulmate/data/datasources/auth_service.dart';

// Generate mocks for FirebaseAuth, GoogleSignIn, User, and UserCredential
@GenerateMocks([
  FirebaseAuth,
  GoogleSignIn,
  User,
  UserCredential,
  GoogleSignInAccount,
  GoogleSignInAuthentication,
])
import 'auth_service_test.mocks.dart';

void main() {
  // Required for FlutterSecureStorage used in signOut()
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock the FlutterSecureStorage platform channel
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return null; // Return success for all secure storage operations
      });

  late MockFirebaseAuth mockAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late AuthService authService;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    authService = AuthService(auth: mockAuth, googleSignIn: mockGoogleSignIn);
  });

  group('AuthService', () {
    test(
      'signInWithEmailAndPassword returns UserCredential on success',
      () async {
        final mockUserCredential = MockUserCredential();
        final mockUser = MockUser();

        // Stub the user property so email verification check succeeds
        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockUser.emailVerified).thenReturn(true);

        when(
          mockAuth.signInWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password',
          ),
        ).thenAnswer((_) async => mockUserCredential);

        final result = await authService.signInWithEmailAndPassword(
          'test@example.com',
          'password',
        );

        expect(result, mockUserCredential);
        verify(
          mockAuth.signInWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password',
          ),
        ).called(1);
      },
    );

    test(
      'registerWithEmailAndPassword returns UserCredential on success',
      () async {
        final mockUserCredential = MockUserCredential();
        final mockUser = MockUser();

        // Stub the user property so email verification logic works
        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockUser.emailVerified).thenReturn(true);

        when(
          mockAuth.createUserWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password',
          ),
        ).thenAnswer((_) async => mockUserCredential);

        final result = await authService.registerWithEmailAndPassword(
          'test@example.com',
          'password',
        );

        expect(result, mockUserCredential);
        verify(
          mockAuth.createUserWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password',
          ),
        ).called(1);
      },
    );

    test('signOut calls signOut on both auth and googleSignIn', () async {
      when(mockGoogleSignIn.signOut()).thenAnswer((_) async => null);
      when(mockAuth.signOut()).thenAnswer((_) async {});

      await authService.signOut();

      verify(mockGoogleSignIn.signOut()).called(1);
      verify(mockAuth.signOut()).called(1);
    });
  });
}
