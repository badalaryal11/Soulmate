import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/user_model.dart';
import '../../data/models/chat_message.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/database_service.dart';
import '../../data/services/image_generation_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/config/dating_persona.dart';
import 'package:provider/provider.dart';
import '../../presentation/providers/user_provider.dart';
import 'package:uuid/uuid.dart';

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/services/notification_service.dart';
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
  final ChatService _chatService = ChatService();
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  late String _currentUserId;
  late String _chatId;
  final Uuid _uuid = const Uuid();
  bool _isTyping = false;

  StreamSubscription<DocumentSnapshot>? _chatSubscription; // NEW
  int _xp = 0; // NEW
  String _relationshipLevel = "Stranger"; // NEW

  @override
  void initState() {
    super.initState();
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      _currentUserId = currentUser.uid;
      _chatId = _databaseService.getChatId(_currentUserId, widget.user.id);

      // Cancel "Miss you" notification as user is here
      _notificationService.cancelNotification(_chatId.hashCode);

      // Listen to XP changes
      _chatSubscription = _databaseService.getChatStream(_chatId).listen((
        snapshot,
      ) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data() as Map<String, dynamic>;
          setState(() {
            _xp = data['xp'] ?? 0;
            _relationshipLevel = _calculateLevel(_xp);
          });
        }
      });
    }
  }

  double _calculateProgress(int xp) {
    if (xp < 10) return xp / 10;
    if (xp < 30) return (xp - 10) / (30 - 10);
    if (xp < 60) return (xp - 30) / (60 - 30);
    if (xp < 100) return (xp - 60) / (100 - 60);
    return 1.0; // Soulmate (Maxed)
  }

  String _calculateLevel(int xp) {
    if (xp < 10) return "Stranger";
    if (xp < 30) return "Acquaintance";
    if (xp < 60) return "Friend";
    if (xp < 100) return "Crush";
    return "Soulmate";
  }

  void _showGamificationDetails() {
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
                  _relationshipLevel,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFE3C72),
                  ),
                ),
                Text(
                  'Level ${(_xp / 10).floor()} • $_xp XP',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                _buildLevelRow('Stranger', 0, _xp >= 0),
                _buildLevelRow('Acquaintance', 10, _xp >= 10),
                _buildLevelRow('Friend', 30, _xp >= 30),
                _buildLevelRow('Crush', 60, _xp >= 60),
                _buildLevelRow('Soulmate', 100, _xp >= 100),
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

  Widget _buildLevelRow(String level, int requiredXp, bool achieved) {
    bool isCurrent = _relationshipLevel == level;
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
    _chatSubscription?.cancel(); // NEW
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
              child: CircleAvatar(
                backgroundImage: widget.user.imageUrl.startsWith('assets/')
                    ? AssetImage(widget.user.imageUrl) as ImageProvider
                    : CachedNetworkImageProvider(
                        ImageGenerationService.generateProfileImageUrl(
                          widget.user,
                        ),
                        maxHeight: 100, // Optimize memory usage
                        maxWidth: 100,
                      ),
                radius: 20,
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
                              '$_relationshipLevel (Lvl ${(_xp / 10).floor()})',
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
                              value: _calculateProgress(_xp),
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
                  if (_isTyping)
                    const Text(
                      'typing...',
                      style: TextStyle(fontSize: 12, color: Color(0xFFFE3C72)),
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
                stream: _databaseService.getMessages(_chatId),
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
                    itemCount: messages.length,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemBuilder: (context, index) {
                      // messages are already ordered descending from firestore
                      // so index 0 is latest
                      final message = messages[index];
                      return MessageBubble(
                        message: message,
                        isMe: message.senderId == _currentUserId,
                      );
                    },
                  );
                },
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
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(_controller.text),
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

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Capture user data before async operations to avoid BuildContext across async gaps
    final currentUser = Provider.of<UserProvider>(
      context,
      listen: false,
    ).currentUser;

    if (currentUser == null) {
      debugPrint("Error: Current user data not available for AI context.");
      return;
    }

    final userMessageText = text.trim();
    _controller.clear();

    // Create User Message
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      senderId: _currentUserId,
      text: userMessageText,
      timestamp: DateTime.now(),
    );

    // Save to Database
    await _databaseService.sendMessage(_chatId, userMessage);

    // Schedule Proactive Notification (Retention Hook)
    try {
      // Cancel any existing notification for this chat
      await _notificationService.cancelNotification(_chatId.hashCode);
      // Schedule a new one for 1 hour later (or 10s for demo if needed)
      await _notificationService.scheduleNotification(
        id: _chatId.hashCode,
        title: '${widget.user.firstName} misses you! 🥺',
        body:
            'Come back and continue your conversation with ${widget.user.firstName}.',
        delay: const Duration(hours: 6),
      );
    } catch (e) {
      debugPrint("Error scheduling notification: $e");
    }

    setState(() => _isTyping = true);

    // Build Chat History for API
    List<Map<String, String>> apiMessages = [];

    // 1. Add System Prompt
    apiMessages.add(DatingPersona.generateFor(widget.user, currentUser));

    // 2. Fetch recent context (last 20 messages)
    try {
      final history = await _databaseService.getMessageHistory(
        _chatId,
        limit: 20,
      );
      // History is descending (newest first), but API needs ascending (oldest first)
      // Reverse it
      for (var msg in history.reversed) {
        apiMessages.add({
          'role': msg.senderId == _currentUserId ? 'user' : 'assistant',
          'content': msg.text,
        });
      }
    } catch (e) {
      debugPrint("Could not fetch history: $e");
    }

    // 3. Add Current Message (it might not be in the history fetch yet due to race/delay)
    // Actually, we just sent it to DB, but Firestore event consistency might be strictly causal.
    // It's safer to explicitly add it to be sure the AI sees it as the *latest* prompt.
    // However, if it WAS fetched in history, we'd duplicate it.
    // Given we just did `await _databaseService.sendMessage`, it IS in the DB.
    // But `limit: 20` might or might not pick it up depending on index latency.
    // Simplest robust way:
    // Filter out the *current* message ID if it appears in history to avoid duplication, then append it.

    // Removing potential duplicate of the message we just sent
    // (We just generated userMessage.id)
    apiMessages.removeWhere(
      (m) => m['content'] == userMessageText && m['role'] == 'user',
    );

    // Re-add the current message at the very end to ensure it's the trigger
    apiMessages.add({'role': 'user', 'content': userMessageText});

    // Send to Chat Service
    try {
      final responseText = await _chatService.sendMessage(apiMessages);

      if (mounted) {
        setState(() => _isTyping = false);

        if (responseText.startsWith("Error: No internet connection")) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "No internet connection. Please check your network.",
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Create AI Message
        final aiMessage = ChatMessage(
          id: _uuid.v4(),
          senderId: widget.user.id,
          text: responseText,
          timestamp: DateTime.now(),
        );

        // Save to Database
        await _databaseService.sendMessage(_chatId, aiMessage);
      }
    } catch (e) {
      debugPrint("Error getting AI response: $e");
      if (mounted) setState(() => _isTyping = false);
    }
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const MessageBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
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
    String hour = time.hour.toString().padLeft(2, '0');
    String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
