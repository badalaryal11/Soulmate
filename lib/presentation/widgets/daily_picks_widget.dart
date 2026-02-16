import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/user_model.dart';
import '../screens/match_screen.dart'; // Reuse MatchScreen styling or similar
import 'package:google_fonts/google_fonts.dart';

class DailyPicksWidget extends StatelessWidget {
  final List<User> users;
  final VoidCallback onClose;

  const DailyPicksWidget({
    super.key,
    required this.users,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your Daily Fate',
            style: GoogleFonts.pacifico(
              fontSize: 28,
              color: const Color(0xFFFE3C72),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '3 special profiles picked just for you today.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final user = users[index];
                return GestureDetector(
                  onTap: () {
                    // Navigate to details or match screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MatchScreen(user: user),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFE3C72),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFFE3C72,
                              ).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: user.imageUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            memCacheWidth: 300,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.firstName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${user.age}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFE3C72),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Maybe Later',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
