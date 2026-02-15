import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soulmate/presentation/screens/create_profile_screen.dart';
import '../unit/providers/user_provider_test.mocks.dart';

void main() {
  late MockUser mockUser;
  late MockDatabaseService mockDatabaseService;

  setUp(() {
    mockUser = MockUser();
    mockDatabaseService = MockDatabaseService();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget createScreen() {
    return MaterialApp(
      home: CreateProfileScreen(
        firebaseUser: mockUser,
        databaseService: mockDatabaseService,
      ),
    );
  }

  testWidgets('Renders correctly with fallback avatar when no photoURL', (
    WidgetTester tester,
  ) async {
    when(mockUser.displayName).thenReturn('John Doe');
    when(mockUser.email).thenReturn('test@test.com');
    when(mockUser.uid).thenReturn('user123');
    when(mockUser.photoURL).thenReturn(null);

    await tester.pumpWidget(createScreen());
    await tester.pump();

    // Verify Title
    expect(find.text('Create Profile'), findsOneWidget);

    // Verify Avatar
    expect(find.byType(CircleAvatar), findsOneWidget);
    // Camera icon should be gone
    expect(find.byIcon(Icons.camera_alt), findsNothing);
    // Fallback person icon should be present
    expect(find.byIcon(Icons.person), findsOneWidget);

    // Verify Fields pre-filled
    expect(find.text('John'), findsOneWidget);
    expect(find.text('Doe'), findsOneWidget);
  });

  testWidgets('Allows saving profile', (WidgetTester tester) async {
    when(mockUser.displayName).thenReturn('John Doe');
    when(mockUser.email).thenReturn('test@test.com');
    when(mockUser.uid).thenReturn('user123');
    when(mockUser.photoURL).thenReturn(null);

    // Mock saveUser call success
    when(mockDatabaseService.saveUser(any)).thenAnswer((_) async {});

    await tester.pumpWidget(createScreen());
    await tester.pump();

    // Fill required fields that are not pre-filled
    await tester.enterText(
      find.widgetWithText(TextFormField, 'City'),
      'New York',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Bio'),
      'Hello world',
    );

    // Tap Continue
    final continueButton = find.text('Continue');
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    verify(mockDatabaseService.saveUser(any)).called(1);
  });
}
