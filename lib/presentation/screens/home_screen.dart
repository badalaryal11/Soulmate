import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import 'package:soulmate/presentation/providers/user_provider.dart';
import 'package:soulmate/presentation/widgets/home_tab.dart';
import 'package:soulmate/presentation/screens/match_screen.dart';
import 'package:soulmate/presentation/screens/matches_screen.dart';
import 'package:soulmate/presentation/screens/settings_screen.dart';
import 'package:soulmate/data/services/auth_service.dart';
import 'package:soulmate/data/services/database_service.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<UserProvider>();

      // Set up match listener
      provider.onMatchFound = (user) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => MatchScreen(user: user)),
          );
        }
      };

      if (provider.users.isEmpty) {
        provider.loadUsers();
      }
    });
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
              leading: IconButton(
                icon: const Icon(
                  Icons.tune_rounded,
                ), // Optimize UX with more modern icon
                onPressed: () => _showFilterDialog(context),
                tooltip: 'Filter Users', // Accessibility
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SettingsScreen(
                            authService: widget.authService,
                            databaseService: widget.databaseService,
                          ),
                        ),
                      );
                    },
                    tooltip: 'Settings', // Accessibility
                  ),
                ),
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
