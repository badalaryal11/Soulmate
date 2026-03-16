import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/stickers.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/chat_message.dart';
import 'package:provider/provider.dart';
import '../../presentation/providers/current_user_provider.dart';
import '../../presentation/providers/match_provider.dart';
import '../../presentation/providers/profile_management_provider.dart';
import '../../presentation/providers/chat_provider.dart';
import '../../presentation/widgets/message_bubble.dart';
import '../../presentation/widgets/typing_bubble.dart';
import '../../presentation/widgets/user_avatar.dart';

import 'details_screen.dart';

class ChatScreen extends StatefulWidget {
  final User user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Initialize provider logic
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = context.read<CurrentUserProvider>().currentUser;
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
      _precacheStickers();
    });
  }

  /// Precache all sticker GIFs in the background so they load instantly
  /// when the user opens the sticker picker.
  void _precacheStickers() {
    for (final sticker in Stickers.stickerData) {
      final url = sticker['url'];
      if (url != null && url.isNotEmpty) {
        precacheImage(
          CachedNetworkImageProvider(url, maxWidth: 250, maxHeight: 250),
          context,
        );
      }
    }
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
    _searchController.dispose();
    _scrollController.dispose();
    // Clean up chat subscriptions when leaving the screen
    context.read<ChatProvider>().disposeProvider();
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
              await context.read<MatchProvider>().unmatchUser(widget.user.id);
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
    final chatProvider = context.read<ChatProvider>();
    final isFav = context.select<CurrentUserProvider, bool>(
      (p) => p.currentUser?.favoriteUserIds.contains(widget.user.id) ?? false,
    );

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
              child: UserAvatar(
                radius: 18,
                imageUrl: widget.user.imageUrl,
                firstName: widget.user.firstName,
                lastName: widget.user.lastName,
                heroTag: 'user-avatar-${widget.user.id}',
                isVerified: widget.user.badges.contains('verified'),
                showGlow: false,
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
                    child: Selector<ChatProvider, (String, int)>(
                      selector: (_, p) => (p.relationshipLevel, p.xp),
                      builder: (context, data, _) {
                        final (level, xp) = data;
                        return Column(
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
                                  '$level (Lvl ${(xp / 10).floor()})',
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
                                  value: chatProvider.calculateProgress(xp),
                                  backgroundColor: Colors.grey[200],
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFFFE3C72),
                                      ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'unmatch') {
                _showUnmatchConfirmation();
              } else if (value == 'favorite') {
                await context.read<ProfileManagementProvider>().toggleFavorite(
                  widget.user.id,
                );
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'favorite',
                  child: Row(
                    children: [
                      Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: const Color(0xFFFE3C72),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isFav ? 'Remove from Favorites' : 'Add to Favorites',
                      ),
                    ],
                  ),
                ),
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
            if (_isSearching)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search messages...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
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
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
            Expanded(
              child: Selector<ChatProvider, (List<ChatMessage>, bool, bool)>(
                selector: (_, p) => (p.messages, p.isTyping, p.isLoading),
                builder: (context, data, _) {
                  final (allMessages, isTyping, isLoading) = data;

                  if (isLoading && allMessages.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = _searchQuery.isEmpty
                      ? allMessages
                      : allMessages
                            .where(
                              (m) => m.text.toLowerCase().contains(
                                _searchQuery,
                              ),
                            )
                            .toList();

                  if (messages.isEmpty && !isLoading) {
                    return Center(
                      child: Text(
                        'Say hello to ${widget.user.firstName}!',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    );
                  }

                  final currentUserId = chatProvider.currentUser?.id ?? '';
                  final chatId = chatProvider.chatId ?? '';

                  return ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    itemCount: messages.length + (isTyping ? 1 : 0),
                    findChildIndexCallback: (Key key) {
                      if (key == const ValueKey('typing_indicator')) {
                        return isTyping ? 0 : null;
                      }
                      if (key is ValueKey<String>) {
                        int index = messages.indexWhere(
                          (m) => m.id == key.value,
                        );
                        if (index != -1) {
                          return isTyping ? index + 1 : index;
                        }
                      }
                      return null;
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemBuilder: (context, index) {
                      if (isTyping) {
                        if (index == 0) {
                          return TypingBubble(
                            key: const ValueKey('typing_indicator'),
                            user: widget.user,
                          );
                        }
                        index -= 1;
                      }
                      final message = messages[index];
                      return RepaintBoundary(
                        child: MessageBubble(
                          key: ValueKey(message.id),
                          message: message,
                          isMe: message.senderId == currentUserId,
                          currentUserId: currentUserId,
                          chatId: chatId,
                          otherUser: widget.user,
                        ),
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
                    child: const CircleAvatar(
                      backgroundColor: Color(0xFFFE3C72),
                      radius: 24,
                      child: Icon(Icons.send, color: Colors.white, size: 20),
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
                        child: CachedNetworkImage(
                          imageUrl: sticker['url']!,
                          fit: BoxFit.cover,
                          memCacheWidth: 250,
                          memCacheHeight: 250,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          placeholder: (context, url) => Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.error_outline, color: Colors.grey, size: 24),
                          ),
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
