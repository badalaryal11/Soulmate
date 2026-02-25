import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import 'package:soulmate/presentation/providers/user_provider.dart';
import 'package:soulmate/presentation/widgets/home_tab.dart';
import 'package:soulmate/presentation/screens/match_screen.dart';
import 'package:soulmate/presentation/screens/matches_screen.dart';
import 'package:soulmate/presentation/screens/settings_screen.dart';
import 'package:soulmate/data/datasources/auth_service.dart';
import 'package:soulmate/data/datasources/database_service.dart';
import 'package:soulmate/presentation/screens/create_profile_screen.dart';
import 'package:soulmate/data/datasources/daily_picks_service.dart';
import 'package:soulmate/presentation/widgets/daily_picks_widget.dart';
import 'package:soulmate/domain/entities/user_model.dart';

class HomeScreen extends StatefulWidget {
  final AuthService? authService;
  final DatabaseService? databaseService;

  const HomeScreen({super.key, this.authService, this.databaseService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CardSwiperController controller = CardSwiperController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<UserProvider>();

      // Set up match listener
      provider.onMatchFound = (user) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => MatchScreen(user: user)),
          );
        }
      };

      // Ensure current user profile is loaded first to get preferences
      await provider.loadCurrentUser();

      if (provider.users.isEmpty) {
        // Load users (filters will be applied based on loaded profile)
        await provider.loadUsers();
      }

      // DAILY PICKS FEATURE
      if (mounted && provider.users.isNotEmpty) {
        _checkDailyPicks(provider.users);
      }

      // Ensure current user profile is loaded for Edit Profile screen
      provider.loadCurrentUser().then((_) {
        if (mounted &&
            provider.currentUser == null &&
            provider.errorMessage == null) {
          // User authenticated but no profile found (and no error occurred)
          // Redirect to Create Profile
          final auth = widget.authService ?? AuthService();
          final authUser = auth.currentUser;
          if (authUser != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) =>
                    CreateProfileScreen(firebaseUser: authUser),
              ),
            );
          }
        }
      });
    });
  }

  Future<void> _checkDailyPicks(List<dynamic> users) async {
    // Cast to List<User> safely
    final userList = users.whereType<User>().toList();
    if (userList.isEmpty) return;

    final picks = await DailyPicksService().getDailyPicks(userList);
    if (picks.isNotEmpty && mounted) {
      // Using a small delay to ensure the UI is ready and it feels natural
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => DailyPicksWidget(
              users: picks,
              onClose: () => Navigator.pop(context),
            ),
          );
        }
      });
    }
  }

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Only show AppBar on Home Tab (Index 0)
      // MatchesScreen (Index 1) has its own AppBar
      appBar: _selectedIndex == 0
          ? AppBar(
              title: Text(
                'Soulmate',
                style: GoogleFonts.pacifico(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFE3C72),
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: PopupMenuButton<String>(
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'Preferences & Settings',
                onSelected: (value) {
                  if (value == 'filters') {
                    _showFilterDialog(context);
                  } else if (value == 'settings') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SettingsScreen(
                          authService: widget.authService,
                          databaseService: widget.databaseService,
                        ),
                      ),
                    );
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<String>(
                      value: 'filters',
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_list,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          const SizedBox(width: 8),
                          const Text('Filters'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(
                            Icons.settings,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          const SizedBox(width: 8),
                          const Text('Settings'),
                        ],
                      ),
                    ),
                  ];
                },
              ),
              actions: [
                Consumer<UserProvider>(
                  builder: (context, provider, child) {
                    final user = provider.currentUser;
                    if (user == null) return const SizedBox.shrink();
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Streak Badge
                        Tooltip(
                          message:
                              'Keep your streak alive to earn more coins! 🔥',
                          triggerMode: TooltipTriggerMode.tap,
                          showDuration: const Duration(seconds: 4),
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(12),
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  '🔥',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${user.streak}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Coins Badge
                        Tooltip(
                          message:
                              'Log in daily to earn coins!\nBonus coins awarded for longer streaks.',
                          triggerMode: TooltipTriggerMode.tap,
                          showDuration: const Duration(seconds: 4),
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(12),
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  '🪙',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${user.coins}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            )
          : null, // Hide AppBar when not on Home tab

      body: IndexedStack(
        index: _selectedIndex,
        children: [_buildHomeTab(), const MatchesScreen()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_rounded),
            label: 'Matches',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFFE3C72),
        onTap: _onItemTapped,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildHomeTab() {
    return HomeTab(controller: controller);
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<UserProvider>(
          builder: (context, provider, child) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter by Gender',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _FilterChip(
                        label: 'Male',
                        isSelected: provider.selectedGender == 'male',
                        onSelected: (bool selected) {
                          if (selected) {
                            provider.loadUsers(gender: 'male', clearList: true);
                            _updateGenderPreference('male');
                          }
                        },
                      ),
                      _FilterChip(
                        label: 'Female',
                        isSelected: provider.selectedGender == 'female',
                        onSelected: (bool selected) {
                          if (selected) {
                            provider.loadUsers(
                              gender: 'female',
                              clearList: true,
                            );
                            _updateGenderPreference('female');
                          }
                        },
                      ),
                      _FilterChip(
                        label: 'Everyone',
                        isSelected:
                            provider.selectedGender == 'everyone' ||
                            provider.selectedGender == null,
                        onSelected: (bool selected) {
                          if (selected) {
                            provider.loadUsers(
                              gender: 'everyone',
                              clearList: true,
                            );
                            _updateGenderPreference('everyone');
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Filter by Age',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${provider.minAge.round()} years',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        '${provider.maxAge.round()} years',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: RangeValues(provider.minAge, provider.maxAge),
                    min: 18,
                    max: 100,
                    divisions: 82,
                    activeColor: const Color(0xFFFE3C72),
                    labels: RangeLabels(
                      provider.minAge.round().toString(),
                      provider.maxAge.round().toString(),
                    ),
                    onChanged: (RangeValues values) {
                      provider.updateAgeRange(values.start, values.end);
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFE3C72),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _updateGenderPreference(String gender) {
    // Determine the value to save: 'male', 'female', or null (for everyone)
    final valueToSave = gender == 'everyone' ? null : gender;

    final auth = widget.authService ?? AuthService();
    final db = widget.databaseService ?? DatabaseService();
    final user = auth.currentUser;
    if (user != null) {
      db.updateUserField(user.uid, {'genderPreference': valueToSave});
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool) onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: const Color(0xFFFE3C72).withValues(alpha: 0.2),
      checkmarkColor: const Color(0xFFFE3C72),
      labelStyle: TextStyle(
        color: isSelected
            ? const Color(0xFFFE3C72)
            : Theme.of(context).textTheme.bodyMedium?.color,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]
          : Colors.grey[200],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFFFE3C72) : Colors.transparent,
        ),
      ),
    );
  }
}
