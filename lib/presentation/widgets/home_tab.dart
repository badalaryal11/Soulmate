import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'profile_card.dart';

class HomeTab extends StatelessWidget {
  final CardSwiperController controller;

  const HomeTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, child) {
        if (provider.status == UserStatus.loading && provider.users.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.status == UserStatus.error && provider.users.isEmpty) {
          return Center(child: Text('Error: ${provider.errorMessage}'));
        }

        if (provider.filteredUsers.isEmpty) {
          return const Center(child: Text('No users match your filters.'));
        }

        return SafeArea(
          child: Column(
            children: [
              Expanded(
                child: CardSwiper(
                  controller: controller,
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
                        if (index < 0 ||
                            index >= provider.filteredUsers.length) {
                          return const SizedBox();
                        }
                        return ProfileCard(user: provider.filteredUsers[index]);
                      },
                  onSwipe: (previousIndex, currentIndex, direction) {
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
                          controller.swipe(CardSwiperDirection.left),
                    ),
                    _ActionButton(
                      icon: Icons.favorite,
                      color: Colors.green,
                      onPressed: () =>
                          controller.swipe(CardSwiperDirection.right),
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
