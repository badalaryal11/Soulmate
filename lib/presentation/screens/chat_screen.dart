import 'package:flutter/material.dart';
import '../../core/utils/image_utils.dart';
import '../../core/constants/stickers.dart';
import '../../domain/entities/user_model.dart';
import '../../domain/entities/chat_message.dart';
import '../../data/datasources/image_generation_service.dart';
import '../../data/datasources/database_service.dart'; // Still needed for MessageBubble (Can be abstracted later)
import 'package:provider/provider.dart';
import '../../presentation/providers/user_provider.dart';
import '../../presentation/providers/chat_provider.dart';

import 'details_screen.dart';

class ChatScreen extends StatefulWidget {
  final User user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DatabaseService _databaseService =
      DatabaseService(); // For MessageBubble compat

  @override
  void initState() {
    super.initState();
    // Initialize provider logic
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = context.read<UserProvider>().currentUser;
      if (currentUser != null) {
        final chatProvider = context.read<ChatProvider>();
        chatProvider.onSoulmateLevelReached = () {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text(
                  '✨ Soulmate Level Reached! ✨',
                  textAlign: TextAlign.center,
                ),
                content: Text(
                  'Congratulations! You and ${widget.user.firstName} are now Soulmates! 💖',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Awesome!'),
                  ),
                ],
              ),
            );
          }
        };
        chatProvider.initChat(currentUser, widget.user);
      }
    });
  }

  void _showGamificationDetails() {
    final chatProvider = context.read<ChatProvider>();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Relationship Journey',
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite, color: Color(0xFFFE3C72), size: 48),
                const SizedBox(height: 10),
                Text(
                  chatProvider.relationshipLevel,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFE3C72),
                  ),
                ),
                Text(
                  'Level ${(chatProvider.xp / 10).floor()} • ${chatProvider.xp} XP',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                _buildLevelRow(
                  'Stranger',
                  0,
                  chatProvider.xp >= 0,
                  chatProvider.relationshipLevel,
                ),
                _buildLevelRow(
                  'Acquaintance',
                  10,
                  chatProvider.xp >= 10,
                  chatProvider.relationshipLevel,
                ),
                _buildLevelRow(
                  'Friend',
                  30,
                  chatProvider.xp >= 30,
                  chatProvider.relationshipLevel,
                ),
                _buildLevelRow(
                  'Crush',
                  60,
                  chatProvider.xp >= 60,
                  chatProvider.relationshipLevel,
                ),
                _buildLevelRow(
                  'Soulmate',
                  100,
                  chatProvider.xp >= 100,
                  chatProvider.relationshipLevel,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLevelRow(
    String level,
    int requiredXp,
    bool achieved,
    String currentLevel,
  ) {
    bool isCurrent = currentLevel == level;
    Color iconColor = Colors.grey;
    if (achieved) iconColor = Colors.green;
    if (isCurrent) iconColor = const Color(0xFFFE3C72);

    Color textColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    if (isCurrent) textColor = const Color(0xFFFE3C72);
    if (!achieved) textColor = Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            achieved ? Icons.check_circle : Icons.lock_outline,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              level,
              style: TextStyle(
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: textColor,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            '$requiredXp XP',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showUnmatchConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unmatch User?'),
        content: Text(
          'Are you sure you want to unmatch with ${widget.user.firstName}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Unmatch logic
              await context.read<UserProvider>().unmatchUser(widget.user.id);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close chat screen
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Unmatch'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DetailsScreen(user: widget.user),
                  ),
                );
              },
              child: ClipOval(
                child: ImageUtils.getImageWidget(
                  (widget.user.imageUrl.isNotEmpty &&
                          !widget.user.imageUrl.startsWith('assets/'))
                      ? widget.user.imageUrl
                      : ImageGenerationService.generateProfileImageUrl(
                          widget.user,
                        ),
                  width: 40,
                  height: 40,
                  memCacheWidth: 100,
                  memCacheHeight: 100,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.firstName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showGamificationDetails,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.favorite,
                              color: Color(0xFFFE3C72),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${chatProvider.relationshipLevel} (Lvl ${(chatProvider.xp / 10).floor()})',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 120,
                            height: 6,
                            child: LinearProgressIndicator(
                              value: chatProvider.calculateProgress(
                                chatProvider.xp,
                              ),
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFFE3C72),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'unmatch') {
                _showUnmatchConfirmation();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'unmatch',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Unmatch', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: chatProvider.messagesStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'Say hello to ${widget.user.firstName}!',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    );
                  }

                  return ListView.builder(
                    reverse: true, // Start from bottom
                    controller: _scrollController,
                    itemCount:
                        messages.length + (chatProvider.isTyping ? 1 : 0),
                    findChildIndexCallback: (Key key) {
                      if (key == const ValueKey('typing_indicator')) {
                        return chatProvider.isTyping ? 0 : null;
                      }
                      if (key is ValueKey<String>) {
                        int index = messages.indexWhere(
                          (m) => m.id == key.value,
                        );
                        if (index != -1) {
                          return chatProvider.isTyping ? index + 1 : index;
                        }
                      }
                      return null;
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemBuilder: (context, index) {
                      if (chatProvider.isTyping) {
                        if (index == 0) {
                          return TypingBubble(
                            key: const ValueKey('typing_indicator'),
                            user: widget.user,
                          );
                        }
                        index -= 1;
                      }
                      // messages are already ordered descending from firestore
                      // so index 0 is latest
                      final message = messages[index];
                      return MessageBubble(
                        key: ValueKey(message.id),
                        message: message,
                        isMe: message.senderId == chatProvider.currentUser?.id,
                        currentUserId: chatProvider.currentUser?.id ?? '',
                        chatId: chatProvider.chatId ?? '',
                        databaseService: _databaseService,
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ActionChip(
                    avatar: const Icon(
                      Icons.casino,
                      size: 16,
                      color: Color(0xFFFE3C72),
                    ),
                    label: const Text('Send Icebreaker'),
                    onPressed: () => chatProvider.sendIcebreaker(),
                    backgroundColor: const Color(
                      0xFFFE3C72,
                    ).withValues(alpha: 0.1),
                    labelStyle: const TextStyle(
                      color: Color(0xFFFE3C72),
                      fontWeight: FontWeight.bold,
                    ),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 1,
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (text) {
                        chatProvider.sendMessage(text);
                        _controller.clear();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _showStickerPicker(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(
                        Icons.emoji_emotions_outlined,
                        color: Colors.grey[500],
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      chatProvider.sendMessage(_controller.text);
                      _controller.clear();
                    },
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFFFE3C72),
                      radius: 24,
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStickerPicker(BuildContext context) {
    final stickerData = Stickers.stickerData;
    final chatProvider = context.read<ChatProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Send a Sticker',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: stickerData.length,
                  itemBuilder: (context, index) {
                    final sticker = stickerData[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        chatProvider.sendSticker(sticker['url']!, index);
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ImageUtils.getImageWidget(
                          sticker['url']!,
                          fit: BoxFit.cover,
                          memCacheWidth: 250,
                          memCacheHeight: 250,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final String currentUserId;
  final String chatId;
  final DatabaseService databaseService;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.currentUserId,
    required this.chatId,
    required this.databaseService,
  });

  @override
  Widget build(BuildContext context) {
    if (message.stickerUrl != null && message.stickerUrl!.isNotEmpty) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Column(
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
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
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
          ],
        ),
      ),
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
