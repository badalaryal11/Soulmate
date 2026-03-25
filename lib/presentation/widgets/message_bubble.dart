import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/chat_message.dart';
import '../../core/utils/image_utils.dart';
import '../../core/utils/image_generation_service.dart';
import 'daily_prompt_bubble.dart';

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
    final avatarImageUrl =
        (otherUser.imageUrl.isNotEmpty &&
            !otherUser.imageUrl.startsWith('assets/'))
        ? otherUser.imageUrl
        : ImageGenerationService.generateProfileImageUrl(otherUser);

    if (message.gameType == 'daily_prompt') {
      return DailyPromptBubble(
        message: message,
        isMe: isMe,
        currentUserId: currentUserId,
        chatId: chatId,
        otherUser: otherUser,
      );
    }

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
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white54
                        : Colors.black54,
                    fontSize: 10,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.70,
      ),
      decoration: BoxDecoration(
        color: isMe
            ? const Color(0xFFFE3C72)
            : (Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[200]),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
          bottomRight: isMe ? Radius.zero : const Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            message.text,
            style: TextStyle(
              color: isMe
                  ? Colors.white
                  : (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  color: isMe
                      ? Colors.white70
                      : (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54),
                  fontSize: 10,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(
                  message.isRead ? Icons.done_all : Icons.done,
                  size: 14,
                  color: message.isRead
                      ? const Color(0xFF4FC3F7)
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
