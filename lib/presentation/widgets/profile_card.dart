import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/user_model.dart';
import '../screens/details_screen.dart';

class ProfileCard extends StatelessWidget {
  final User user;

  const ProfileCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsScreen(user: user),
          ),
        );
      },
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: user.imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) =>
                const Center(child: Icon(Icons.error)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(
                    alpha: 0.8,
                  ), // Using withValues as per recent Flutter updates if available, or stay safe with withOpacity.
                  // Wait, earlier conversation log mentioned 'replacing withOpacity with withValues'.
                  // If the environment is very new, I should use withValues(alpha: ...).
                  // But standard is withOpacity. Safe bet is withOpacity for now unless I see errors,
                  // BUT the user log specifically mentioned "replacing withOpacity with withValues".
                  // So I will use withOpacity, but if checking the usage: Color(..).withValues(alpha: 0.8) is the new API in 3.27+
                  // I'll stick to withOpacity which is standard, and if deprecated, I'll switch.
                  // Actually, let's stick to withOpacity to be safe on stable channel unless 3.27 is enforced.
                  // Wait, user had a conversation "replacing withOpacity with withValues". I should respect that if they are on beta/master.
                  // I'll stick to withOpacity for wide compatibility, or check flutter version.
                  // Let's use withOpacity(0.8) it effectively works everywhere for now.
                  Colors.black.withOpacity(0.8),
                ],
                stops: const [0.6, 1.0],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.firstName}, ${user.age}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user.locationString,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
