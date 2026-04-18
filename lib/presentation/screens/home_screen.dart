import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import 'package:soulmate/presentation/providers/current_user_provider.dart';
import 'package:soulmate/presentation/providers/discovery_provider.dart';
import 'package:soulmate/presentation/providers/profile_management_provider.dart';
import 'package:soulmate/presentation/providers/notification_provider.dart';
import 'package:soulmate/presentation/widgets/home_tab.dart';
import 'package:soulmate/presentation/providers/match_provider.dart';
import 'package:soulmate/presentation/screens/match_screen.dart';
import 'package:soulmate/presentation/screens/matches_list_screen.dart';
import 'package:soulmate/core/di/service_locator.dart';
import 'package:soulmate/core/utils/image_generation_service.dart';
import 'package:soulmate/presentation/widgets/profile_tab.dart';
import 'package:soulmate/presentation/widgets/filter_chip_widget.dart';

import 'package:soulmate/presentation/screens/create_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CardSwiperController controller = CardSwiperController();
  late final DiscoveryProvider _discoveryProvider;

  @override
  void initState() {
    super.initState();
    _discoveryProvider = context.read<DiscoveryProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentUserProvider = context.read<CurrentUserProvider>();
      final discoveryProvider = _discoveryProvider;

      // Set up match listener
      discoveryProvider.onMatchFound = (user) {
        if (mounted) {
          final notificationProvider = context.read<NotificationProvider>();
          if (notificationProvider.matchesEnabled) {
            ServiceLocator.notificationRepository.scheduleNotification(
              id: user.hashCode,
              title: 'New Match! 🎉',
              body: 'You and ${user.firstName} liked each other. Say hi!',
              delay: const Duration(seconds: 1), 
            );
          }

          // Precache images so the match screen loads instantly
          final matchedImageUrl = user.imageUrl.isNotEmpty
              ? user.imageUrl
              : ImageGenerationService.generateProfileImageUrl(user);
          final currentImageUrl =
              currentUserProvider.currentUser?.imageUrl ?? '';

          if (matchedImageUrl.isNotEmpty) {
            precacheImage(
              CachedNetworkImageProvider(matchedImageUrl, maxWidth: 300, maxHeight: 450), 
              context,
            );
          }
          if (currentImageUrl.isNotEmpty &&
              !currentImageUrl.startsWith('assets/') &&
              !currentImageUrl.startsWith('file://')) {
            precacheImage(
              CachedNetworkImageProvider(currentImageUrl, maxWidth: 300, maxHeight: 450), 
              context,
            );
          }

          context.read<MatchProvider>().addMatch(user);

          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => MatchScreen(user: user)),
          );
        }
      };

      // Load current user profile first
      await currentUserProvider.loadCurrentUser();

      if (mounted) {
        context.read<MatchProvider>().loadMatches();
      }

      // If no profile exists, redirect to Create Profile
      if (mounted && currentUserProvider.currentUser == null) {
        final authUser = ServiceLocator.authRepository.currentUser;
        if (authUser != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => CreateProfileScreen(firebaseUser: authUser),
            ),
          );
          return;
        }
      }

      // Now load users with the correct gender preference from the start
      if (mounted) {
        discoveryProvider.loadUsers(
          gender: currentUserProvider.currentUser?.genderPreference,
          clearList: true,
        );
      }
    });
  }

  int _selectedIndex = 0;

  @override
  void dispose() {
    // Use the cached reference — calling context.read<>() inside dispose() is unsafe
    _discoveryProvider.onMatchFound = null;
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Only show AppBar on Home Tab (Index 0)
      // MatchesScreen (Index 1) has its own AppBar
      appBar: _selectedIndex == 0
          ? AppBar(
              title: Text(
                'Soulmate',
                style: GoogleFonts.lobster(
                  fontSize:
                      30, // Slightly reduced to fit with balanced side widths
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFE3C72),
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              toolbarHeight: 70,
              leadingWidth:
                  100, // Balanced with actions width, reduced to prevent title truncation
              leading: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.tune_rounded),
                    tooltip: 'Filters',
                    onPressed: () {
                      _showFilterDialog(context);
                    },
                  ),
                ),
              ),
              actions: [
                Selector<CurrentUserProvider, (int, int)>(
                  selector: (context, provider) {
                    final user = provider.currentUser;
                    return (user?.streak ?? 0, user?.coins ?? 0);
                  },
                  builder: (context, data, child) {
                    final streak = data.$1;
                    final coins = data.$2;
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
                                  '$streak',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4), // Tightened spacing
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
                                  '$coins',
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
                const SizedBox(width: 4), // Tightened end spacing
              ],
            )
          : null, // Hide AppBar when not on Home tab

      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),
          MatchesListScreen(isActive: _selectedIndex == 1),
          const ProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_rounded),
            label: 'Matches',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
        return Consumer<DiscoveryProvider>(
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
                      FilterChipWidget(
                        label: 'Male',
                        isSelected: provider.selectedGender == 'male',
                        onSelected: (bool selected) {
                          if (selected) {
                            provider.loadUsers(gender: 'male', clearList: true);
                            _updateGenderPreference('male');
                          }
                        },
                      ),
                      FilterChipWidget(
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
                      FilterChipWidget(
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

    final user = ServiceLocator.authRepository.currentUser;
    if (user != null) {
      if (mounted) {
        context.read<ProfileManagementProvider>().updateUserField(user.uid, {
          'genderPreference': valueToSave,
        });
      }
    }
  }
}
