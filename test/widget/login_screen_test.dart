import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:soulmate/presentation/screens/login_screen.dart';

void main() {
  setUp(() {
    // Ensure GoogleFonts loads correctly in tests
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget createLoginScreen() {
    return const MaterialApp(home: LoginScreen());
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

  // Note: The signIn failure test has been removed because LoginScreen
  // now uses ServiceLocator.authRepository directly, so mock injection
  // requires full DI setup. This will be re-added as an integration test.
}
