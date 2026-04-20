import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/stickers.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/user.dart';
import '../../presentation/providers/chat_provider.dart';
import '../../presentation/providers/current_user_provider.dart';
import '../../presentation/providers/match_provider.dart';
import '../../presentation/providers/profile_management_provider.dart';
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
                  'Soulmate Level Reached',
                  textAlign: TextAlign.center,
                ),
                content: Text(
                  'Congratulations! You and ${widget.user.firstName} are now Soulmates.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Awesome'),
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

  Future<void> _precacheStickers() async {
    for (final sticker in Stickers.stickerData) {
      if (!mounted) break;
      final url = sticker['url'];
      if (url != null && url.isNotEmpty) {
        await precacheImage(
          CachedNetworkImageProvider(url, maxWidth: 250, maxHeight: 250),
          context,
        );
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  void _sendCurrentText(ChatProvider chatProvider) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    chatProvider.sendMessage(text);
    _controller.clear();
  }

  void _showGamificationDetails() {
    final chatProvider = context.read<ChatProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                Icon(
                  Icons.favorite_rounded,
                  color: colorScheme.primary,
                  size: 44,
                ),
                const SizedBox(height: 12),
                Text(
                  chatProvider.relationshipLevel,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Level ${(chatProvider.xp / 10).floor()} • ${chatProvider.xp} XP',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.72,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Divider(color: colorScheme.outline.withValues(alpha: 0.45)),
                const SizedBox(height: 8),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCurrent = currentLevel == level;
    Color iconColor = theme.hintColor;
    if (achieved) iconColor = const Color(0xFF24A76E);
    if (isCurrent) iconColor = colorScheme.primary;

    var textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    if (isCurrent) textColor = colorScheme.primary;
    if (!achieved) textColor = textColor.withValues(alpha: 0.55);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            achieved ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              level,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          Text(
            '$requiredXp XP',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.textTheme.labelMedium?.color?.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnmatchConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unmatch user?'),
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
              await context.read<MatchProvider>().unmatchUser(widget.user.id);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final chatProvider = context.read<ChatProvider>();
    final isFav = context.select<CurrentUserProvider, bool>(
      (p) => p.currentUser?.pinnedUserIds.contains(widget.user.id) ?? false,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface.withValues(
          alpha: isDark ? 0.78 : 0.9,
        ),
        surfaceTintColor: Colors.transparent,
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
                heroTag: 'user-avatar-${widget.user.id}-chat',
                isVerified: widget.user.badges.contains('verified'),
                showGlow: false,
                useRoundShape: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.user.firstName,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showGamificationDetails,
                    child: Selector<ChatProvider, (String, int)>(
                      selector: (_, p) => (p.relationshipLevel, p.xp),
                      builder: (context, data, _) {
                        final (level, xp) = data;
                        final progress = chatProvider.calculateProgress(xp);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.favorite_rounded,
                                  color: colorScheme.primary,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '$level • Lvl ${(xp / 10).floor()}',
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: theme.textTheme.labelSmall?.color
                                          ?.withValues(alpha: 0.82),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: SizedBox(
                                width: 132,
                                height: 5,
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor:
                                      colorScheme.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.primary,
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
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
            ),
            tooltip: _isSearching ? 'Close search' : 'Search messages',
            onPressed: _toggleSearch,
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
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: colorScheme.primary,
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
                      Icon(
                        Icons.person_remove_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text('Unmatch', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ];
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isSearching)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(
                      AppThemeTokens.radiusLg,
                    ),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search messages...',
                      prefixIcon: Icon(Icons.search_rounded, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
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
                              (m) =>
                                  m.text.toLowerCase().contains(_searchQuery),
                            )
                            .toList();

                  if (messages.isEmpty && !isLoading) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _searchQuery.isNotEmpty
                              ? 'No messages match your search.'
                              : 'Say hello to ${widget.user.firstName}.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.textTheme.bodyLarge?.color?.withValues(
                              alpha: 0.65,
                            ),
                          ),
                        ),
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
                        final index = messages.indexWhere(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ActionChip(
                  avatar: Icon(
                    Icons.casino_rounded,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  label: const Text('Send Icebreaker'),
                  onPressed: () => chatProvider.sendIcebreaker(),
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                  side: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.26),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.92),
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
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
                        fillColor: colorScheme.surfaceContainerHighest
                            .withValues(alpha: isDark ? 0.65 : 0.92),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.45),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 1.2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                      ),
                      onSubmitted: (_) => _sendCurrentText(chatProvider),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: () => _showStickerPicker(context),
                    icon: Icon(
                      Icons.emoji_emotions_outlined,
                      color: theme.iconTheme.color?.withValues(alpha: 0.78),
                    ),
                    tooltip: 'Stickers',
                  ),
                  const SizedBox(width: 2),
                  GestureDetector(
                    onTap: () => _sendCurrentText(chatProvider),
                    child: CircleAvatar(
                      backgroundColor: colorScheme.primary,
                      radius: 22,
                      child: const Icon(
                        Icons.send_rounded,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            height: 420,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outline.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Send a Sticker',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppThemeTokens.radiusMd,
                            ),
                            border: Border.all(
                              color: colorScheme.outline.withValues(
                                alpha: 0.45,
                              ),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppThemeTokens.radiusMd - 1,
                            ),
                            child: CachedNetworkImage(
                              imageUrl: sticker['url']!,
                              fit: BoxFit.cover,
                              memCacheWidth: 250,
                              memCacheHeight: 250,
                              fadeInDuration: Duration.zero,
                              fadeOutDuration: Duration.zero,
                              placeholder: (context, url) => Container(
                                color: colorScheme.surfaceContainerHighest,
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.error_outline_rounded,
                                  color: theme.iconTheme.color?.withValues(
                                    alpha: 0.62,
                                  ),
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
