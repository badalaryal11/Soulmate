import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:soulmate/core/di/service_locator.dart';
import 'package:soulmate/domain/repositories/auth_repository.dart';
import 'package:soulmate/domain/repositories/user_repository.dart';
import 'package:soulmate/presentation/screens/settings_screen.dart';
import 'package:soulmate/presentation/providers/theme_provider.dart';
import 'package:soulmate/presentation/providers/notification_provider.dart';
import 'package:soulmate/presentation/providers/login_provider.dart';
import 'package:soulmate/domain/repositories/notification_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {
  @override
  Future<void> signOut() => super.noSuchMethod(
    Invocation.method(#signOut, []),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

class MockUserRepository extends Mock implements UserRepository {}


void main() {
  late MockAuthRepository mockAuthRepository;
  late MockNotificationRepository mockNotificationRepository;
  late MockUserRepository mockUserRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockNotificationRepository = MockNotificationRepository();
    mockUserRepository = MockUserRepository();
    ServiceLocator.setMockRepositories(
      authRepository: mockAuthRepository,
      userRepository: mockUserRepository,
    );
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(
            notificationRepository: mockNotificationRepository,
          ),
        ),
        ChangeNotifierProvider<LoginProvider>(
          create: (_) => ServiceLocator.createLoginProvider(),
        ),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    );
  }

  group('SettingsScreen Widget Tests', () {
    testWidgets('SettingsScreen renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('Sign Out button calls authRepository.signOut', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Sign Out'), 100);
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      verify(mockAuthRepository.signOut()).called(1);
    });
  });
}
