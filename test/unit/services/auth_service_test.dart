import 'package:flutter_test/flutter_test.dart';
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
  late MockFirebaseAuth mockAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late AuthService authService;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    // We need to inject mocks into AuthService, but AuthService currently instantiates them internally.
    // Ideally, we should refactor AuthService to accept dependencies.
    // Since we cannot easily change AuthService without potentially breaking other things or if we do,
    // we should execute a refactor.
    // However, AuthService has fields:
    // final FirebaseAuth _auth = FirebaseAuth.instance;
    // final GoogleSignIn _googleSignIn = GoogleSignIn();
    // These are final and private. We can't set them from outside.

    // START REFACTOR PLAN:
    // 1. Modify AuthService to allow dependency injection.
    // 2. Update existing usages to use default instances.

    // For now, I will write the test assuming I will refactor AuthService in the next step.
    authService = AuthService(auth: mockAuth, googleSignIn: mockGoogleSignIn);
  });

  group('AuthService', () {
    test(
      'signInWithEmailAndPassword returns UserCredential on success',
      () async {
        final mockUserCredential = MockUserCredential();
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
