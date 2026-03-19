import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import '../providers/discovery_provider.dart';
import '../../core/utils/image_generation_service.dart';
import '../../core/utils/image_utils.dart';
import 'profile_card.dart';

class HomeTab extends StatefulWidget {
  final CardSwiperController controller;

  const HomeTab({super.key, required this.controller});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  int _lastPrecachedRevision = -1;

  @override
  Widget build(BuildContext context) {
    return Consumer<DiscoveryProvider>(
      builder: (context, provider, child) {
        if ((provider.status == DiscoveryStatus.loading ||
                provider.status == DiscoveryStatus.initial) &&
            provider.users.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.status == DiscoveryStatus.error &&
            provider.users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.errorMessage ?? 'Unknown error',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => provider.loadUsers(clearList: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFE3C72),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        if (provider.filteredUsers.isEmpty) {
          // Auto-load more users when deck is empty
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) provider.loadUsers(gender: provider.selectedGender);
          });

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  'Searching for new profiles...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hold on, we\'re finding people for you!',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => provider.loadUsers(clearList: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        // Fire-and-forget precaching of upcoming images (no UI blocking)
        if (_lastPrecachedRevision != provider.filterRevision) {
          _lastPrecachedRevision = provider.filterRevision;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            for (int i = 0; i < 3 && i < provider.filteredUsers.length; i++) {
              _precacheUserImage(context, provider.filteredUsers[i]);
            }
          });
        }

        return SafeArea(
          child: Column(
            children: [
              Expanded(
                child: CardSwiper(
                  key: ValueKey(provider.filterRevision),
                  controller: widget.controller,
                  cardsCount: provider.filteredUsers.length,
                  numberOfCardsDisplayed: provider.filteredUsers.length < 3
                      ? provider.filteredUsers.length
                      : 3,
                  backCardOffset: const Offset(0, 40),
                  padding: const EdgeInsets.all(24.0),
                  cardBuilder:
                      (
                        context,
                        index,
                        horizontalOffsetPercentage,
                        verticalOffsetPercentage,
                      ) {
                        return ProfileCard(user: provider.filteredUsers[index]);
                      },
                  onSwipe: (previousIndex, currentIndex, direction) {
                    // Pre-cache upcoming images
                    if (currentIndex != null) {
                      for (int i = 1; i <= 3; i++) {
                        final nextIndex = currentIndex + i;
                        if (nextIndex < provider.filteredUsers.length) {
                          _precacheUserImage(
                            context,
                            provider.filteredUsers[nextIndex],
                          );
                        }
                      }
                    }

                    provider.userSwiped(previousIndex, direction);
                    return true;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ActionButton(
                      icon: Icons.close,
                      color: Colors.red,
                      onPressed: () =>
                          widget.controller.swipe(CardSwiperDirection.left),
                    ),
                    _ActionButton(
                      icon: Icons.favorite,
                      color: Colors.green,
                      onPressed: () =>
                          widget.controller.swipe(CardSwiperDirection.right),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _precacheUserImage(BuildContext context, dynamic user) async {
    if (user == null) return;

    String? url;
    if (user.imageUrl.isNotEmpty && !user.imageUrl.startsWith('assets/')) {
      url = user.imageUrl;
    } else if (user.imageUrl.isEmpty) {
      url = ImageGenerationService.generateProfileImageUrl(user);
    }

    if (url != null && url.isNotEmpty) {
      final imageProvider = ImageUtils.getImageProvider(
        url,
        maxWidth: 300,
        maxHeight: 450,
      );
      if (imageProvider == null) return;
      try {
        await precacheImage(imageProvider, context);
      } catch (e) {
        debugPrint('Image precache error: $e');
      }
    }
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
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 30),
        padding: const EdgeInsets.all(15),
      ),
    );
  }
}
