import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:soulmate/presentation/providers/user_provider.dart';
import 'package:soulmate/data/repositories/user_repository.dart';
import 'package:soulmate/data/datasources/auth_service.dart';
import 'package:soulmate/data/datasources/database_service.dart';
import 'package:soulmate/domain/entities/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

// Generate mocks
@GenerateMocks([
  UserRepository,
  AuthService,
  DatabaseService,
  firebase_auth.User,
])
import 'user_provider_test.mocks.dart';

void main() {
  late MockUserRepository mockUserRepository;
  late MockAuthService mockAuthService;
  late MockDatabaseService mockDatabaseService;
  late UserProvider userProvider;

  setUp(() {
    mockUserRepository = MockUserRepository();
    mockAuthService = MockAuthService();
    mockDatabaseService = MockDatabaseService();

    userProvider = UserProvider(
      userRepository: mockUserRepository,
      authService: mockAuthService,
      databaseService: mockDatabaseService,
    );
  });

  group('UserProvider', () {
    test('initial status is initial', () {
      expect(userProvider.status, UserStatus.initial);
    });

    test('loadCurrentUser updates status and user', () async {
      final mockFirebaseUser = MockUser();
      when(mockFirebaseUser.uid).thenReturn('test_uid');
      when(mockAuthService.currentUser).thenReturn(mockFirebaseUser);

      final user = User(
        id: 'test_uid',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        age: 25,
        city: 'City',
        country: 'Country',
        imageUrl: 'url',
        gender: 'Male',
        interests: ['Coding'],
      );

      when(
        mockDatabaseService.getUser('test_uid'),
      ).thenAnswer((_) async => user);

      when(
        mockDatabaseService.getActiveChats('test_uid'),
      ).thenAnswer((_) async => []);

      when(
        mockDatabaseService.updateUserField(any, any),
      ).thenAnswer((_) async => {});

      await userProvider.loadCurrentUser();

      expect(userProvider.currentUser?.id, user.id);
      expect(userProvider.currentUser?.email, user.email);
      expect(userProvider.currentUserInterests, ['Coding']);
      verify(mockAuthService.currentUser).called(1);
      verify(mockDatabaseService.getUser('test_uid')).called(1);
    });

    test('loadUsers updates status and users list', () async {
      final users = [
        User(
          id: '1',
          email: '1@test.com',
          firstName: 'One',
          lastName: 'User',
          age: 20,
          city: 'City',
          country: 'Country',
          imageUrl: 'url',
          gender: 'Female',
          interests: [],
        ),
      ];

      when(
        mockUserRepository.getUsers(gender: anyNamed('gender')),
      ).thenAnswer((_) async => users);

      await userProvider.loadUsers();

      expect(userProvider.status, UserStatus.loaded);
      expect(userProvider.users.length, 1);
      expect(userProvider.users.first.id, '1');
      verify(mockUserRepository.getUsers(gender: anyNamed('gender'))).called(1);
    });
  });
}
