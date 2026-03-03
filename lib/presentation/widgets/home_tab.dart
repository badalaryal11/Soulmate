import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../../core/utils/image_generation_service.dart';
import 'profile_card.dart';

class HomeTab extends StatefulWidget {
  final CardSwiperController controller;

  const HomeTab({super.key, required this.controller});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _isFirstImagePrecached = false;
  int _lastPrecachedRevision = -1;

  @override
  void initState() {
    super.initState();
    // Pre-caching is now handled dynamically in the build method
    // when provider.filteredUsers becomes available or updates.
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, child) {
        if ((provider.status == UserStatus.loading ||
                provider.status == UserStatus.initial) &&
            provider.users.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.status == UserStatus.error && provider.users.isEmpty) {
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_off_outlined,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'No users found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Try adjusting your filters or retrying.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => provider.loadUsers(clearList: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFE3C72),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        // Trigger precaching when users are loaded or filters change
        if (_lastPrecachedRevision != provider.filterRevision) {
          _lastPrecachedRevision = provider.filterRevision;
          _isFirstImagePrecached = false;

          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;

            final futures = <Future>[];
            for (int i = 0; i < 8 && i < provider.filteredUsers.length; i++) {
              futures.add(
                _precacheUserImage(context, provider.filteredUsers[i]),
              );
            }

            if (futures.isNotEmpty) {
              try {
                // Wait for up to 3 seconds for the first image
                await futures.first.timeout(const Duration(seconds: 3));
              } catch (_) {}
            }

            if (mounted) {
              setState(() {
                _isFirstImagePrecached = true;
              });
            }
          });
        }

        // Wait for first image to precache
        if (provider.filteredUsers.isNotEmpty && !_isFirstImagePrecached) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFE3C72)),
            ),
          );
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
                    // ---------------------------------------------------------
                    // OPTIMIZATION: PRE-CACHE NEXT IMAGES
                    // ---------------------------------------------------------
                    // When we swipe to 'currentIndex', the card at 'currentIndex' is now top.
                    // The card at 'currentIndex + 1' becomes visible behind it.
                    // We should look ahead and cache 'currentIndex + 2' and 'currentIndex + 3'.

                    // We check the next 2 cards ahead of what is currently visible
                    // CardSwiper displays 3 cards. If we are at index `i`, visible are `i`, `i+1`, `i+2`.
                    // The next one to load is `i+3`.

                    // Let's precache `currentIndex + 1` (next visible), `currentIndex + 2` (behind that)
                    // and `currentIndex + 3` (just in case).

                    if (currentIndex != null) {
                      // Aggressive Pre-caching: Look ahead 8 cards
                      for (int i = 1; i <= 8; i++) {
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
                      icon: Icons.undo,
                      color: provider.canUndo
                          ? Colors.amber
                          : Colors.grey[400]!,
                      onPressed: () {
                        if (provider.canUndo) {
                          provider.undoSwipe();
                          widget.controller.undo();
                        }
                      },
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
    } else if (user.imageUrl.isEmpty || !user.imageUrl.startsWith('assets/')) {
      url = ImageGenerationService.generateProfileImageUrl(user);
    }

    if (url != null && url.isNotEmpty) {
      try {
        await precacheImage(
          CachedNetworkImageProvider(url, maxWidth: 300, maxHeight: 450),
          context,
        );
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
