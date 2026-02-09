import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soulmate/presentation/screens/login_screen.dart';
import '../unit/providers/user_provider_test.mocks.dart';

void main() {
  late MockAuthService mockAuthService;
  late MockDatabaseService mockDatabaseService;

  setUp(() {
    mockAuthService = MockAuthService();
    mockDatabaseService = MockDatabaseService();
    // Ensure GoogleFonts loads correctly in tests
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget createLoginScreen() {
    return MaterialApp(
      home: LoginScreen(
        authService: mockAuthService,
        databaseService: mockDatabaseService,
      ),
    );
  }

  testWidgets('LoginScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createLoginScreen());

    // Check for Logo and Google logo
    expect(find.byType(Image), findsNWidgets(2));

    // Check for Text
    expect(find.text('Welcome!'), findsOneWidget);
    expect(find.text('Log in to find your soulmate.'), findsOneWidget);

    // Check for TextFields
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Email or Mobile Number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    // Check for Buttons
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Register now'), findsOneWidget);
  });

  testWidgets('Shows error if fields are empty', (WidgetTester tester) async {
    await tester.pumpWidget(createLoginScreen());

    // Tap Sign In button without entering text
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    // Verify SnackBar appears
    expect(find.text('Please enter email and password'), findsOneWidget);
  });

  testWidgets('Calls signIn and shows error on failure', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createLoginScreen());

    // Enter credentials
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email or Mobile Number'),
      'test@test.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password',
    );

    // Mock failure
    when(
      mockAuthService.signInWithEmailAndPassword('test@test.com', 'password'),
    ).thenThrow(Exception('Auth Failed'));

    // Tap Sign In
    await tester.tap(find.text('Sign In'));
    await tester.pump(); // Start loading
    await tester.pump(); // Complete future

    // Verify error snackbar
    expect(find.textContaining('Login failed'), findsOneWidget);
  });
}
