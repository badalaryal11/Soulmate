import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soulmate/presentation/screens/home_screen.dart';
import 'package:soulmate/presentation/providers/user_provider.dart';
import 'package:soulmate/domain/entities/user.dart' as model;
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Manual Mock for UserProvider
class MockUserProvider extends ChangeNotifier implements UserProvider {
  UserStatus _status = UserStatus.initial;
  String? _errorMessage;
  List<model.User> _users = [];
  List<model.User> _filteredUsers = [];
  List<model.User> _matches = [];

  @override
  UserStatus get status => _status;

  set status(UserStatus value) {
    _status = value;
    notifyListeners();
  }

  @override
  String? get errorMessage => _errorMessage;

  set errorMessage(String? value) {
    _errorMessage = value;
    notifyListeners();
  }

  @override
  List<model.User> get users => _users;

  set users(List<model.User> value) {
    _users = value;
    notifyListeners();
  }

  @override
  List<model.User> get filteredUsers => _filteredUsers;

  set filteredUsers(List<model.User> value) {
    _filteredUsers = value;
    notifyListeners();
  }

  @override
  List<model.User> get matches => _matches;

  set matches(List<model.User> value) {
    _matches = value;
    notifyListeners();
  }

  @override
  int get filterRevision => 0;

  void setStatus(UserStatus status) {
    _status = status;
    notifyListeners();
  }

  @override
  double minAge = 18;

  @override
  double maxAge = 100;

  @override
  String? selectedGender = 'everyone';

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
  Future<void> unmatchUser(String userId) async {}

  @override
  Future<void> updateUserField(String uid, Map<String, dynamic> data) async {}

  @override
  Future<void> saveFeedback(String userId, String message) async {}

  @override
  Future<String> uploadProfileImage(String userId, dynamic imageFile) async =>
      '';

  @override
  void updateLocalUser(model.User user) {
    currentUser = user;
    notifyListeners();
  }

  @override
  Future<void> loadMatches() async {}

  @override
  bool get canUndo => false;

  @override
  void undoSwipe() {}
}

void main() {
  late MockUserProvider mockUserProvider;

  setUp(() {
    mockUserProvider = MockUserProvider();
    GoogleFonts.config.allowRuntimeFetching = false;

    mockUserProvider.currentUser = model.User(
      id: 'test_current_user',
      email: 'test@test.com',
      firstName: 'Current',
      lastName: 'User',
      age: 25,
      city: 'NY',
      country: 'USA',
      imageUrl: 'https://example.com/image.jpg',
      gender: 'male',
      interests: ['Music'],
    );
  });

  Widget createHomeScreen() {
    return ChangeNotifierProvider<UserProvider>.value(
      value: mockUserProvider,
      child: MaterialApp(home: const HomeScreen()),
    );
  }

  testWidgets('HomeScreen renders AppBar and bottom navigation', (
    WidgetTester tester,
  ) async {
    await mockNetworkImagesFor(() async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createHomeScreen());
      await tester.pump();

      expect(find.text('Soulmate'), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

      // Verify 3 bottom navigation items exist
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.items.length, 3);

      expect(find.text('Home'), findsWidgets);
      expect(find.text('Matches'), findsWidgets);
      expect(find.text('Profile'), findsWidgets);
    });
  });

  testWidgets('HomeScreen shows loading indicator when loading', (
    WidgetTester tester,
  ) async {
    mockUserProvider.status = UserStatus.loading;
    mockUserProvider.users = [];

    await mockNetworkImagesFor(() async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createHomeScreen());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  testWidgets('HomeScreen shows no users message when empty', (
    WidgetTester tester,
  ) async {
    mockUserProvider.status = UserStatus.loaded;
    mockUserProvider.filteredUsers = [];

    await mockNetworkImagesFor(() async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createHomeScreen());
      await tester.pump();

      expect(find.text('No users found'), findsOneWidget);
    });
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

    await mockNetworkImagesFor(() async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createHomeScreen());
      await tester.pump();

      expect(find.text('John, 25'), findsOneWidget);
      expect(find.text('NY, USA'), findsOneWidget);
    });
  });

  // Note: Navigation test removed as SettingsScreen is tested separately in settings_screen_test.dart
  // Testing navigation here would require full Firebase initialization which isn't available in unit tests
}
