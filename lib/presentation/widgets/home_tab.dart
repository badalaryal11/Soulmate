import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import '../providers/discovery_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/image_generation_service.dart';
import '../../core/utils/image_utils.dart';
import 'profile_card.dart';

class HomeTab extends StatelessWidget {
  final CardSwiperController controller;

  const HomeTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Consumer<DiscoveryProvider>(
      builder: (context, provider, child) {
        if ((provider.status == DiscoveryStatus.loading ||
                provider.status == DiscoveryStatus.initial) &&
            provider.users.isEmpty) {
          return const _StatusPanel(
            icon: CircularProgressIndicator(),
            title: 'Finding great profiles',
            subtitle: 'We are curating a new stack for you.',
          );
        }

        if (provider.status == DiscoveryStatus.error &&
            provider.users.isEmpty) {
          return _StatusPanel(
            icon: Icon(
              Icons.error_outline_rounded,
              size: 46,
              color: Theme.of(context).colorScheme.error,
            ),
            title: 'Could not load discovery',
            subtitle: provider.errorMessage ?? 'Please try again.',
            actionLabel: 'Retry',
            onAction: () => provider.loadUsers(clearList: true),
          );
        }

        if (provider.filteredUsers.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.loadUsers(gender: provider.selectedGender);
          });

          return _StatusPanel(
            icon: const CircularProgressIndicator(),
            title: 'Refreshing your deck',
            subtitle: 'Hold on while we load more people nearby.',
            actionLabel: 'Refresh',
            onAction: () => provider.loadUsers(clearList: true),
          );
        }

        final colorScheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        // Eagerly pre-cache the first 3 images so swiping feels instantaneous
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          final limit = provider.filteredUsers.length < 3 ? provider.filteredUsers.length : 3;
          for (int i = 0; i < limit; i++) {
            final user = provider.filteredUsers[i];
            // ProfileCard will use cacheWidth/memCacheWidth 600, so we match it here
            final imageProvider = ImageUtils.getImageProvider(
              user.imageUrl.isNotEmpty ? user.imageUrl : ImageGenerationService.generateProfileImageUrl(user),
              maxWidth: 600,
            );
            if (imageProvider != null) {
              precacheImage(imageProvider, context).catchError((_) {}); // Ignore errors silently
            }
          }
        });

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.surfaceContainerHighest.withValues(
                  alpha: isDark ? 0.22 : 0.55,
                ),
                Theme.of(context).scaffoldBackgroundColor,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: CardSwiper(
                    key: ValueKey(provider.filterRevision),
                    controller: controller,
                    cardsCount: provider.filteredUsers.length,
                    numberOfCardsDisplayed:
                        provider.filteredUsers.length < 3
                            ? provider.filteredUsers.length
                            : 3,
                    backCardOffset: const Offset(0, 36),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    cardBuilder: (
                      context,
                      index,
                      horizontalOffsetPercentage,
                      verticalOffsetPercentage,
                    ) {
                      return ProfileCard(
                        user: provider.filteredUsers[index],
                      );
                    },
                    onSwipe: (previousIndex, currentIndex, direction) {
                      final swipedUser =
                          previousIndex >= 0 &&
                                  previousIndex <
                                      provider.filteredUsers.length
                              ? provider.filteredUsers[previousIndex]
                              : null;

                      if (swipedUser != null) {
                        provider.userSwiped(swipedUser, direction);
                      }
                      return true;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppThemeTokens.spaceLg,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(
                        alpha: isDark ? 0.84 : 0.92,
                      ),
                      borderRadius: BorderRadius.circular(
                        AppThemeTokens.radiusLg,
                      ),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.65),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ActionButton(
                          icon: Icons.close_rounded,
                          color: const Color(0xFFE0526D),
                          onPressed: () =>
                              controller.swipe(CardSwiperDirection.left),
                        ),
                        _ActionButton(
                          icon: Icons.favorite_rounded,
                          color: const Color(0xFF1DAD75),
                          onPressed: () => controller.swipe(
                            CardSwiperDirection.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: color.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 30),
        padding: const EdgeInsets.all(16),
        style: IconButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.14),
          foregroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StatusPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 18),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.8,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 180,
                child: FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
