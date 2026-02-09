import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soulmate/presentation/screens/settings_screen.dart';
import 'package:soulmate/presentation/providers/theme_provider.dart';
import 'package:soulmate/presentation/providers/notification_provider.dart';
import '../unit/providers/user_provider_test.mocks.dart';

// We need a mock for ThemeProvider and NotificationProvider since they are ChangeNotifiers
class MockThemeProvider extends Mock implements ThemeProvider {
  @override
  ThemeMode get themeMode => ThemeMode.light;
  @override
  bool get isDarkMode => false;
}

class MockNotificationProvider extends Mock implements NotificationProvider {
  @override
  bool get areNotificationsEnabled => true;
}

void main() {
  late MockAuthService mockAuthService;
  late MockDatabaseService mockDatabaseService;
  late MockThemeProvider mockThemeProvider;
  late MockNotificationProvider mockNotificationProvider;

  setUp(() {
    mockAuthService = MockAuthService();
    mockDatabaseService = MockDatabaseService();
    mockThemeProvider = MockThemeProvider();
    mockNotificationProvider = MockNotificationProvider();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget createSettingsScreen() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        ChangeNotifierProvider<NotificationProvider>.value(
          value: mockNotificationProvider,
        ),
      ],
      child: MaterialApp(
        home: SettingsScreen(
          authService: mockAuthService,
          databaseService: mockDatabaseService,
        ),
      ),
    );
  }

  testWidgets('SettingsScreen renders all sections', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSettingsScreen());

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Preferences'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Actions'), findsOneWidget);
  });

  testWidgets('Sign Out button calls authService.signOut', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSettingsScreen());

    final signOutTile = find.text('Sign Out');
    await tester.ensureVisible(signOutTile);
    expect(signOutTile, findsOneWidget);

    when(mockAuthService.signOut()).thenAnswer((_) async {});

    await tester.tap(signOutTile);
    await tester.pumpAndSettle();

    verify(mockAuthService.signOut()).called(1);
  });

  testWidgets('About Soulmate shows dialog', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSettingsScreen());

    final aboutTile = find.text('About Soulmate');
    await tester.ensureVisible(aboutTile);
    await tester.tap(aboutTile);
    await tester.pumpAndSettle();

    expect(find.text('Version 1.0.0'), findsOneWidget);
    expect(find.text('Features:'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });
}
