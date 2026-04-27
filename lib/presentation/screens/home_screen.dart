import 'dart:async';

import 'package:flutter/material.dart';
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
import 'package:soulmate/core/theme/app_theme.dart';
import 'package:soulmate/core/utils/image_generation_service.dart';
import 'package:soulmate/core/utils/image_utils.dart';
import 'package:soulmate/presentation/widgets/profile_tab.dart';
import 'package:soulmate/presentation/widgets/filter_chip_widget.dart';

import 'package:soulmate/presentation/screens/create_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _StatBadge extends StatelessWidget {
  final String icon;
  final String value;
  final Color background;
  final Color textColor;

  const _StatBadge({
    required this.icon,
    required this.value,
    required this.background,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppThemeTokens.radiusMd),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 5),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgePill extends StatelessWidget {
  final String label;

  const _AgePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppThemeTokens.radiusSm),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  final CardSwiperController controller = CardSwiperController();
  late final DiscoveryProvider _discoveryProvider;

  @override
  void initState() {
    super.initState();
    _discoveryProvider = context.read<DiscoveryProvider>();

    // Set up match listener immediately so we don't miss early swipes
    _discoveryProvider.onMatchFound = (user) {
      if (!mounted) return;

      final notificationProvider = context.read<NotificationProvider>();
      if (notificationProvider.matchesEnabled) {
        ServiceLocator.notificationRepository.scheduleNotification(
          id: user.hashCode,
          title: 'New Match! 🎉',
          body: 'You and ${user.firstName} liked each other. Say hi!',
          delay: const Duration(seconds: 1),
        );
      }

      // Add immediately so match is visible in list even if precache fails.
      context.read<MatchProvider>().addMatch(user);

      // Pre-cache in background. This must never block navigation.
      final matchedImageUrl = user.imageUrl.isNotEmpty
          ? user.imageUrl
          : ImageGenerationService.generateProfileImageUrl(user);
      final currentImageUrl = context.read<CurrentUserProvider>().currentUser?.imageUrl ?? '';
      unawaited(_safePrecacheMatchImage(matchedImageUrl));
      unawaited(_safePrecacheMatchImage(currentImageUrl));

      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => MatchScreen(user: user)),
      );
    };

    _discoveryProvider.onMatchUndone = (user) {
      if (!mounted) return;
      context.read<MatchProvider>().unmatchUser(user.id);
    };

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentUserProvider = context.read<CurrentUserProvider>();

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
        _discoveryProvider.loadUsers(
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
    _discoveryProvider.onMatchUndone = null;
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const double appBarSideSlotWidth = 132;

    return Scaffold(
      // Only show AppBar on Home Tab (Index 0)
      // MatchesScreen (Index 1) has its own AppBar
      appBar: _selectedIndex == 0
          ? AppBar(
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              title: Row(
                children: [
                  SizedBox(
                    width: appBarSideSlotWidth,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              AppThemeTokens.radiusMd,
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.tune_rounded,
                              color: colorScheme.primary,
                            ),
                            tooltip: 'Filters',
                            onPressed: () {
                              _showFilterDialog(context);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Soulmate',
                          maxLines: 1,
                          style: GoogleFonts.lobster(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: appBarSideSlotWidth,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Selector<CurrentUserProvider, (int, int)>(
                        selector: (context, provider) {
                          final user = provider.currentUser;
                          return (user?.streak ?? 0, user?.coins ?? 0);
                        },
                        builder: (context, data, child) {
                          final streak = data.$1;
                          final coins = data.$2;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Tooltip(
                                  message:
                                      'Keep your streak alive to earn more coins! 🔥',
                                  triggerMode: TooltipTriggerMode.tap,
                                  showDuration: const Duration(seconds: 4),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: _StatBadge(
                                    icon: '🔥',
                                    value: '$streak',
                                    background: const Color(
                                      0xFFFFA647,
                                    ).withValues(alpha: 0.22),
                                    textColor: const Color(0xFFB86200),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Tooltip(
                                  message:
                                      'Log in daily to earn coins!\nBonus coins awarded for longer streaks.',
                                  triggerMode: TooltipTriggerMode.tap,
                                  showDuration: const Duration(seconds: 4),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: _StatBadge(
                                    icon: '🪙',
                                    value: '$coins',
                                    background: const Color(
                                      0xFFFFD65C,
                                    ).withValues(alpha: 0.24),
                                    textColor: const Color(0xFF7A5B00),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: colorScheme.surface.withValues(
                alpha: isDark ? 0.78 : 0.88,
              ),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              toolbarHeight: 70,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_rounded),
            label: 'Matches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        showUnselectedLabels: true,
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

  Future<void> _safePrecacheMatchImage(String imageUrl) async {
    if (!mounted || imageUrl.isEmpty) return;

    final imageProvider = ImageUtils.getImageProvider(
      imageUrl,
      maxWidth: 300,
      maxHeight: 450,
    );
    if (imageProvider == null) return;

    try {
      await precacheImage(imageProvider, context);
    } catch (e) {
      debugPrint('Failed to precache match image "$imageUrl": $e');
    }
  }

  void _showFilterDialog(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Consumer<DiscoveryProvider>(
          builder: (context, provider, child) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerTheme.color,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('Refine Discovery', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Set who appears in your swipe deck.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.72,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Gender', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilterChipWidget(
                          label: 'Male',
                          isSelected: provider.selectedGender == 'male',
                          onSelected: (bool selected) {
                            if (selected) {
                              provider.loadUsers(
                                gender: 'male',
                                clearList: true,
                              );
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
                    Text('Age Range', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _AgePill(label: '${provider.minAge.round()} years'),
                        _AgePill(label: '${provider.maxAge.round()} years'),
                      ],
                    ),
                    RangeSlider(
                      values: RangeValues(provider.minAge, provider.maxAge),
                      min: 18,
                      max: 100,
                      divisions: 82,
                      labels: RangeLabels(
                        provider.minAge.round().toString(),
                        provider.maxAge.round().toString(),
                      ),
                      onChanged: (RangeValues values) {
                        provider.updateAgeRange(values.start, values.end);
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Apply Filters'),
                      ),
                    ),
                  ],
                ),
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
