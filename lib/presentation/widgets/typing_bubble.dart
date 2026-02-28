import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';
import '../../core/utils/image_utils.dart';
import '../../data/datasources/image_generation_service.dart';

class TypingBubble extends StatelessWidget {
  final User user;

  const TypingBubble({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl =
        (user.imageUrl.isNotEmpty && !user.imageUrl.startsWith('assets/'))
        ? user.imageUrl
        : ImageGenerationService.generateProfileImageUrl(user);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ClipOval(
            child: ImageUtils.getImageWidget(
              imageUrl,
              width: 28,
              height: 28,
              memCacheWidth: 70,
              memCacheHeight: 70,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(0),
              ),
            ),
            child: const SizedBox(
              width: 40,
              height: 20,
              child: Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFFE3C72),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
