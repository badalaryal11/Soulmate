import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:soulmate/presentation/providers/user_provider.dart';
import 'package:soulmate/domain/repositories/user_repository.dart';
import 'package:soulmate/domain/entities/user_model.dart';
import 'package:soulmate/data/datasources/auth_service.dart';
import 'package:soulmate/data/datasources/database_service.dart';

// Generate mocks
@GenerateMocks([UserRepository, AuthService, DatabaseService])
import 'user_provider_test.mocks.dart';

void main() {
  late UserProvider userProvider;
  late MockUserRepository mockUserRepository;
  late MockAuthService mockAuthService;
  late MockDatabaseService mockDatabaseService;

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

  group('UserProvider Gender Filtering', () {
    final userMale = User(
      id: '1',
      email: 'male@test.com',
      firstName: 'John',
      lastName: 'Doe',
      age: 25,
      city: 'NY',
      country: 'USA',
      imageUrl: 'url',
      gender: 'male',
      interests: [],
    );

    final userFemale = User(
      id: '2',
      email: 'female@test.com',
      firstName: 'Jane',
      lastName: 'Doe',
      age: 25,
      city: 'NY',
      country: 'USA',
      imageUrl: 'url',
      gender: 'female',
      interests: [],
    );

    test(
      'Initial load with no gender preference should fetch with null gender',
      () async {
        when(mockAuthService.currentUser).thenReturn(null);
        when(
          mockUserRepository.getUsers(
            gender: anyNamed('gender'),
            currentUserId: anyNamed('currentUserId'),
          ),
        ).thenAnswer((_) async => []);

        await userProvider.loadUsers();

        verify(
          mockUserRepository.getUsers(gender: null, currentUserId: null),
        ).called(1);
      },
    );

    test('loadUsers with "male" filters users correctly', () async {
      // Setup: Repository returns mixed users (simulating API that might return mixed or just to test client-side filter)
      when(mockAuthService.currentUser).thenReturn(null);
      when(
        mockUserRepository.getUsers(
          gender: 'male',
          currentUserId: anyNamed('currentUserId'),
        ),
      ).thenAnswer((_) async => [userMale, userFemale]);

      // Act
      await userProvider.loadUsers(gender: 'male', clearList: true);

      // Assert
      // The provider receives both from repo, but should filter out female if client-side filtering works
      // Current implementation triggers _updateFilteredUsers() which uses _selectedGender
      expect(userProvider.selectedGender, 'male');

      // Let's verify what filteredUsers contains
      // Logic: user.gender.toLowerCase() == _selectedGender?.toLowerCase()
      // 'female' != 'male' -> should be excluded
      expect(userProvider.filteredUsers.length, 1);
      expect(userProvider.filteredUsers.first.id, userMale.id);
    });

    test('loadUsers with "female" filters users correctly', () async {
      when(mockAuthService.currentUser).thenReturn(null);
      when(
        mockUserRepository.getUsers(
          gender: 'female',
          currentUserId: anyNamed('currentUserId'),
        ),
      ).thenAnswer((_) async => [userMale, userFemale]);

      await userProvider.loadUsers(gender: 'female', clearList: true);

      expect(userProvider.selectedGender, 'female');
      expect(userProvider.filteredUsers.length, 1);
      expect(userProvider.filteredUsers.first.id, userFemale.id);
    });

    test('loadUsers with "everyone" returns all users', () async {
      when(mockAuthService.currentUser).thenReturn(null);
      when(
        mockUserRepository.getUsers(
          gender: 'everyone',
          currentUserId: anyNamed('currentUserId'),
        ),
      ).thenAnswer((_) async => [userMale, userFemale]);

      await userProvider.loadUsers(gender: 'everyone', clearList: true);

      expect(userProvider.selectedGender, 'everyone');
      expect(userProvider.filteredUsers.length, 2);
    });

    test('Filtering is case insensitive', () async {
      final userMaleUpper = userMale.copyWith(gender: 'Male');
      when(mockAuthService.currentUser).thenReturn(null);
      when(
        mockUserRepository.getUsers(
          gender: 'male',
          currentUserId: anyNamed('currentUserId'),
        ),
      ).thenAnswer((_) async => [userMaleUpper]);

      await userProvider.loadUsers(gender: 'male', clearList: true);

      expect(userProvider.filteredUsers.length, 1);
      expect(userProvider.filteredUsers.first.id, userMaleUpper.id);
    });

    test('Trimming whitespace in gender string', () async {
      // This test is expected to fail with current implementation if we don't trim
      final userMaleSpace = userMale.copyWith(gender: ' male ');
      when(mockAuthService.currentUser).thenReturn(null);
      when(
        mockUserRepository.getUsers(
          gender: 'male',
          currentUserId: anyNamed('currentUserId'),
        ),
      ).thenAnswer((_) async => [userMaleSpace]);

      await userProvider.loadUsers(gender: 'male', clearList: true);

      // If strict match, this might fail unless we enhance the logic
      expect(userProvider.filteredUsers.length, 1);
    });
  });
}
