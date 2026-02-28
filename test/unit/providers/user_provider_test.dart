import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:soulmate/presentation/providers/user_provider.dart';
import 'package:soulmate/domain/repositories/user_repository.dart';
import 'package:soulmate/data/datasources/auth_service.dart';
import 'package:soulmate/data/datasources/database_service.dart';
import 'package:soulmate/domain/entities/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'package:soulmate/domain/usecases/get_users_usecase.dart';
import 'package:soulmate/domain/usecases/get_active_chats_usecase.dart';
import 'package:soulmate/domain/usecases/delete_chat_usecase.dart';
import 'package:soulmate/domain/usecases/get_chat_id_usecase.dart';
import 'package:soulmate/domain/usecases/save_feedback_usecase.dart';
import 'package:soulmate/domain/usecases/upload_profile_image_usecase.dart';
import 'package:soulmate/domain/usecases/update_user_field_usecase.dart';
import 'package:soulmate/domain/usecases/get_current_user_usecase.dart';

// Generate mocks
@GenerateMocks([
  UserRepository,
  AuthService,
  DatabaseService,
  firebase_auth.User,
  GetUsersUseCase,
  GetActiveChatsUseCase,
  DeleteChatUseCase,
  GetChatIdUseCase,
  SaveFeedbackUseCase,
  UploadProfileImageUseCase,
  UpdateUserFieldUseCase,
  GetCurrentUserUseCase,
])
import 'user_provider_test.mocks.dart';

void main() {
  late MockUserRepository mockUserRepository;
  late MockAuthService mockAuthService;
  late MockGetUsersUseCase mockGetUsersUseCase;
  late MockGetActiveChatsUseCase mockGetActiveChatsUseCase;
  late MockDeleteChatUseCase mockDeleteChatUseCase;
  late MockGetChatIdUseCase mockGetChatIdUseCase;
  late MockSaveFeedbackUseCase mockSaveFeedbackUseCase;
  late MockUploadProfileImageUseCase mockUploadProfileImageUseCase;
  late MockUpdateUserFieldUseCase mockUpdateUserFieldUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late UserProvider userProvider;

  setUp(() {
    mockUserRepository = MockUserRepository();
    mockAuthService = MockAuthService();
    mockGetUsersUseCase = MockGetUsersUseCase();
    mockGetActiveChatsUseCase = MockGetActiveChatsUseCase();
    mockDeleteChatUseCase = MockDeleteChatUseCase();
    mockGetChatIdUseCase = MockGetChatIdUseCase();
    mockSaveFeedbackUseCase = MockSaveFeedbackUseCase();
    mockUploadProfileImageUseCase = MockUploadProfileImageUseCase();
    mockUpdateUserFieldUseCase = MockUpdateUserFieldUseCase();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();

    userProvider = UserProvider(
      userRepository: mockUserRepository,
      authService: mockAuthService,
      getUsersUseCase: mockGetUsersUseCase,
      getActiveChatsUseCase: mockGetActiveChatsUseCase,
      deleteChatUseCase: mockDeleteChatUseCase,
      getChatIdUseCase: mockGetChatIdUseCase,
      saveFeedbackUseCase: mockSaveFeedbackUseCase,
      uploadProfileImageUseCase: mockUploadProfileImageUseCase,
      updateUserFieldUseCase: mockUpdateUserFieldUseCase,
      getCurrentUserUseCase: mockGetCurrentUserUseCase,
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
        mockUserRepository.getUser('test_uid'),
      ).thenAnswer((_) async => user);

      when(mockGetActiveChatsUseCase(any)).thenAnswer((_) async => []);

      await userProvider.loadCurrentUser();

      expect(userProvider.currentUser?.id, user.id);
      expect(userProvider.currentUser?.email, user.email);
      expect(userProvider.currentUserInterests, ['Coding']);
      verify(mockAuthService.currentUser).called(1);
      verify(mockUserRepository.getUser('test_uid')).called(1);
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
