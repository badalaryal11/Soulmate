import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:soulmate/core/di/service_locator.dart';
import 'package:soulmate/domain/repositories/auth_repository.dart';
import 'package:soulmate/domain/repositories/user_repository.dart';
import 'package:soulmate/presentation/screens/login_screen.dart';
import 'package:soulmate/presentation/providers/theme_provider.dart';
import 'package:soulmate/presentation/providers/login_provider.dart';

class MockAuthRepository extends Mock implements AuthRepository {
  @override
  Future<void> sendPasswordResetEmail(String? email) => super.noSuchMethod(
    Invocation.method(#sendPasswordResetEmail, [email]),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
}

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockUserRepository mockUserRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
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
        ChangeNotifierProvider<LoginProvider>(
          create: (_) => ServiceLocator.createLoginProvider(),
        ),
      ],
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('LoginScreen renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Soulmate'), findsOneWidget);
      expect(find.text('Find your perfect connection.'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));

      // Specific image checks
      final logoFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/logo_transparent.png',
      );
      expect(logoFinder, findsOneWidget);

      final googleLogoFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/google_logo.png',
      );
      expect(googleLogoFinder, findsOneWidget);
    });

    testWidgets('Shows error if fields are empty', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });
  });
}
