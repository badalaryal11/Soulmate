import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';
import '../../core/utils/image_utils.dart';
import '../../core/utils/image_generation_service.dart';
import '../../core/theme/app_theme.dart';

class TypingBubble extends StatelessWidget {
  final User user;

  const TypingBubble({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
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
          const SizedBox(width: AppThemeTokens.spaceXs),
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
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: isDark ? 0.64 : 0.88,
              ),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.45),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(0),
              ),
            ),
            child: Text(
              'typing...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(
                  alpha: 0.72,
                ),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
