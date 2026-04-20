import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/chat_message.dart';
import '../../core/utils/image_utils.dart';
import '../../core/utils/image_generation_service.dart';
import '../../core/theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final String currentUserId;
  final String chatId;
  final User otherUser;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.currentUserId,
    required this.chatId,
    required this.otherUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final avatarImageUrl =
        (otherUser.imageUrl.isNotEmpty &&
            !otherUser.imageUrl.startsWith('assets/'))
        ? otherUser.imageUrl
        : ImageGenerationService.generateProfileImageUrl(otherUser);

    if (message.stickerUrl != null && message.stickerUrl!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              ClipOval(
                child: ImageUtils.getImageWidget(
                  avatarImageUrl,
                  width: 28,
                  height: 28,
                  memCacheWidth: 70,
                  memCacheHeight: 70,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ImageUtils.getImageWidget(
                    message.stickerUrl!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    memCacheWidth: 250,
                    memCacheHeight: 250,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.textTheme.labelSmall?.color?.withValues(
                      alpha: 0.65,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.70,
      ),
      decoration: BoxDecoration(
        color: isMe
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest.withValues(
                alpha: isDark ? 0.62 : 0.85,
              ),
        border: isMe
            ? null
            : Border.all(color: colorScheme.outline.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: isMe ? const Radius.circular(18) : Radius.zero,
          bottomRight: isMe ? Radius.zero : const Radius.circular(18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            message.text,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isMe
                  ? Colors.white
                  : theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.94),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(message.timestamp),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isMe
                      ? Colors.white70
                      : theme.textTheme.labelSmall?.color?.withValues(
                          alpha: 0.65,
                        ),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(
                  message.isRead ? Icons.done_all : Icons.done,
                  size: 14,
                  color: message.isRead
                      ? const Color(0xFF58D5FF)
                      : Colors.white70,
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (isMe) {
      return Align(alignment: Alignment.centerRight, child: bubble);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(width: AppThemeTokens.spaceXs),
        ClipOval(
          child: ImageUtils.getImageWidget(
            avatarImageUrl,
            width: 28,
            height: 28,
            memCacheWidth: 70,
            memCacheHeight: 70,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(child: bubble),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }
}
