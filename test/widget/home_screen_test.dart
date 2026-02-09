import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soulmate/presentation/screens/home_screen.dart';
import 'package:soulmate/presentation/providers/user_provider.dart';
import 'package:soulmate/data/models/user_model.dart' as model;
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../unit/providers/user_provider_test.mocks.dart';

// Manual Mock for UserProvider
class MockUserProvider extends ChangeNotifier implements UserProvider {
  @override
  UserStatus status = UserStatus.loaded;

  @override
  List<model.User> users = [];

  @override
  List<model.User> filteredUsers = [];

  @override
  List<model.User> matches = [];

  @override
  double minAge = 18;

  @override
  double maxAge = 100;

  @override
  String? selectedGender = 'everyone';

  @override
  String? errorMessage;

  @override
  List<String> currentUserInterests = [];

  @override
  model.User? currentUser;

  @override
  Function(model.User)? onMatchFound;

  @override
  Future<void> loadUsers({String? gender, bool clearList = false}) async {}

  @override
  void updateAgeRange(double min, double max) {
    minAge = min;
    maxAge = max;
    notifyListeners();
  }

  @override
  void userSwiped(int index, CardSwiperDirection direction) {}

  @override
  Future<void> loadCurrentUser() async {}

  @override
  void setInterests(List<String> interests) {}

  @override
  void unmatchUser(String userId) {}
}

void main() {
  late MockUserProvider mockUserProvider;
  late MockAuthService mockAuthService;
  late MockDatabaseService mockDatabaseService;

  setUp(() {
    mockUserProvider = MockUserProvider();
    mockAuthService = MockAuthService();
    mockDatabaseService = MockDatabaseService();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget createHomeScreen() {
    return ChangeNotifierProvider<UserProvider>.value(
      value: mockUserProvider,
      child: MaterialApp(
        home: HomeScreen(
          authService: mockAuthService,
          databaseService: mockDatabaseService,
        ),
      ),
    );
  }

  testWidgets('HomeScreen renders AppBar and bottom navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createHomeScreen());
    await tester.pump();

    expect(find.text('Soulmate'), findsOneWidget);
    expect(find.byIcon(Icons.filter_list), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.byIcon(Icons.home), findsOneWidget);
  });

  testWidgets('HomeScreen shows loading indicator when loading', (
    WidgetTester tester,
  ) async {
    mockUserProvider.status = UserStatus.loading;
    mockUserProvider.users = [];

    await tester.pumpWidget(createHomeScreen());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('HomeScreen shows no users message when empty', (
    WidgetTester tester,
  ) async {
    mockUserProvider.status = UserStatus.loaded;
    mockUserProvider.filteredUsers = [];

    await tester.pumpWidget(createHomeScreen());
    await tester.pump();

    expect(find.text('No users match your filters.'), findsOneWidget);
  });

  testWidgets('HomeScreen renders profile cards', (WidgetTester tester) async {
    mockUserProvider.status = UserStatus.loaded;
    mockUserProvider.filteredUsers = [
      model.User(
        id: '1',
        email: 'test@test.com',
        firstName: 'John',
        lastName: 'Doe',
        age: 25,
        city: 'NY',
        country: 'USA',
        imageUrl: 'https://example.com/image.jpg',
        gender: 'male',
        interests: ['Music'],
      ),
    ];

    await tester.pumpWidget(createHomeScreen());
    await tester.pump();

    expect(find.text('John, 25'), findsOneWidget);
    expect(find.text('NY, USA'), findsOneWidget);
  });

  // Note: Navigation test removed as SettingsScreen is tested separately in settings_screen_test.dart
  // Testing navigation here would require full Firebase initialization which isn't available in unit tests
}
