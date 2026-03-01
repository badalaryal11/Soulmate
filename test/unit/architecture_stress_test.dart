import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:soulmate/presentation/providers/user_provider.dart';
import 'package:soulmate/domain/entities/user.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter/foundation.dart';
import 'user_provider_test.mocks.dart';

void main() {
  late UserProvider userProvider;
  late MockUserRepository mockUserRepository;
  late MockAuthRepository mockAuthRepository;
  late MockGetUsersUseCase mockGetUsersUseCase;
  late MockGetActiveChatsUseCase mockGetActiveChatsUseCase;
  late MockDeleteChatUseCase mockDeleteChatUseCase;
  late MockGetChatIdUseCase mockGetChatIdUseCase;
  late MockSaveFeedbackUseCase mockSaveFeedbackUseCase;
  late MockUploadProfileImageUseCase mockUploadProfileImageUseCase;
  late MockUpdateUserFieldUseCase mockUpdateUserFieldUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;

  setUp(() {
    mockUserRepository = MockUserRepository();
    mockAuthRepository = MockAuthRepository();
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
      authRepository: mockAuthRepository,
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

  group('Architecture Stress Tests', () {
    test(
      'UserProvider can handle loading 5000 users and applying strict memory limits',
      () async {
        // Create 5000 mock users
        final largeUserList = List.generate(
          5000,
          (index) => User(
            id: 'user_$index',
            email: 'user$index@test.com',
            firstName: 'Test$index',
            lastName: 'User',
            age: 20 + (index % 40),
            city: 'NY',
            country: 'USA',
            imageUrl: 'http://example.com/url_$index',
            gender: index % 2 == 0 ? 'male' : 'female',
            interests: [],
          ),
        );

        when(mockAuthRepository.currentUser).thenReturn(null);
        when(
          mockUserRepository.getUsers(
            gender: anyNamed('gender'),
            currentUserId: anyNamed('currentUserId'),
          ),
        ).thenAnswer((_) async => largeUserList);

        final stopwatch = Stopwatch()..start();

        await userProvider.loadUsers(clearList: true);

        stopwatch.stop();

        expect(userProvider.users.length, lessThanOrEqualTo(200));
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));

        debugPrint(
          '✅ Loaded 5000 users in ${stopwatch.elapsedMilliseconds} ms. Capped to: ${userProvider.users.length} to prevent OOM.',
        );

        // Stress test swiping
        stopwatch.reset();
        stopwatch.start();

        for (int i = 0; i < 150; i++) {
          userProvider.userSwiped(i, CardSwiperDirection.right);
        }
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(1000),
          reason: '150 rapid right swipes took too long',
        );
        debugPrint(
          '✅ 150 massive right swipes processed seamlessly in ${stopwatch.elapsedMilliseconds} ms. Matches triggered logic without blocking thread.',
        );
      },
    );
  });
}
