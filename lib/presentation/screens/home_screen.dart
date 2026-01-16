import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/profile_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CardSwiperController controller = CardSwiperController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Soulmate',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFFE3C72),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<UserProvider>(
        builder: (context, provider, child) {
          if (provider.status == UserStatus.loading && provider.users.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.status == UserStatus.error && provider.users.isEmpty) {
            return Center(child: Text('Error: ${provider.errorMessage}'));
          }

          if (provider.users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: CardSwiper(
                    controller: controller,
                    cardsCount: provider.users.length,
                    numberOfCardsDisplayed: 3,
                    backCardOffset: const Offset(0, 40),
                    padding: const EdgeInsets.all(24.0),
                    cardBuilder:
                        (
                          context,
                          index,
                          horizontalOffsetPercentage,
                          verticalOffsetPercentage,
                        ) {
                          return ProfileCard(user: provider.users[index]);
                        },
                    onSwipe: (previousIndex, currentIndex, direction) {
                      provider.userSwiped(
                        currentIndex ?? previousIndex,
                      ); // API might differ on version, handling safely
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
      ),
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
            color: Colors.grey.withOpacity(0.2),
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
