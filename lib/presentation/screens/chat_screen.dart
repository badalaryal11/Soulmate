import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/user_model.dart';
import '../../data/models/chat_message.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/database_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/config/dating_persona.dart';
import 'package:provider/provider.dart';
import '../../presentation/providers/user_provider.dart';
import 'package:uuid/uuid.dart';

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/services/notification_service.dart';

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

  String _calculateLevel(int xp) {
    if (xp < 10) return "Stranger";
    if (xp < 30) return "Acquaintance";
    if (xp < 60) return "Friend";
    if (xp < 100) return "Crush";
    return "Soulmate";
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
            onPressed: () {
              // Unmatch logic
              context.read<UserProvider>().unmatchUser(widget.user.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close chat screen
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
            CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(widget.user.imageUrl),
              radius: 20,
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
                  Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        color: const Color(0xFFFE3C72),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_relationshipLevel (Lv.${(_xp / 10).floor()})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  if (_isTyping)
                    const Text(
                      'typing...',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFFFE3C72),
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
                color: Colors.white,
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
                        fillColor: Colors.grey[100],
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

    setState(() => _isTyping = true);

    // Prepare API messages history
    // We need to fetch history or use local state if acceptable,
    // but for correctness let's just pass the last few messages if possible,
    // or just the current message + system prompt if we want to save reads.
    // For now, let's keep it simple and just do prompt + new message
    // to avoid complex async fetching logic inside sendMessage.
    // Ideally we should pull `messages` from the stream snapshot but
    // accessing it here is tricky without a provider buffer.

    // Simpler: Just send current context
    List<Map<String, String>> apiMessages = [];
    apiMessages.add(DatingPersona.generateFor(widget.user));
    apiMessages.add({'role': 'user', 'content': userMessageText});

    // Send to Chat Service
    try {
      final responseText = await _chatService.sendMessage(apiMessages);

      if (mounted) {
        setState(() => _isTyping = false);

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
          color: isMe ? const Color(0xFFFE3C72) : Colors.grey[200],
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
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.black54,
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
