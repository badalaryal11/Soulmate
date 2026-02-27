import 'package:flutter/material.dart';
import '../../core/utils/image_utils.dart';
import '../../domain/entities/user_model.dart';
import '../../domain/entities/chat_message.dart';
import '../../data/datasources/chat_service.dart';
import '../../data/datasources/database_service.dart';
import '../../data/datasources/image_generation_service.dart';
import '../../data/datasources/auth_service.dart';
import '../../core/config/dating_persona.dart';
import 'package:provider/provider.dart';
import '../../presentation/providers/user_provider.dart';
import 'package:uuid/uuid.dart';

import 'dart:async';
import '../../data/datasources/notification_service.dart';
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

  StreamSubscription<Map<String, dynamic>?>? _chatSubscription; // NEW
  int _xp = 0; // NEW
  bool _isFirstLoad = true;
  String _relationshipLevel = "Stranger"; // NEW

  final List<String> _icebreakers = [
    "Two truths and a lie, go!",
    "What's your most controversial food opinion?",
    "If you could teleport anywhere right now, where to?",
    "What's the best show you've watched recently?",
    "What's a hobby you've always wanted to pick up?",
    "What's your ideal first date?",
    "If you could have dinner with any historical figure, who would it be?",
    "What's the most unusual job you've ever had?",
    "If you had to eat one meal for the rest of your life, what would it be?",
    "What's the best piece of advice you've ever received?",
    "What's a movie you can practically quote from start to finish?",
    "If you were a superhero, what would your superpower be?",
    "What's the most spontaneous thing you've ever done?",
    "What's a hidden talent you have that most people don't know about?",
    "If you could instantly become an expert in any subject, what would it be?",
    "What's your favorite way to spend a lazy Sunday?",
    "What's the most interesting place you've ever visited?",
    "If your life was a movie, what genre would it be?",
    "What's a song that always puts you in a good mood?",
    "If you could live in any fictional universe, which one would you choose?",
    "What's the weirdest dream you've ever had?",
    "What's a bucket list item you're determined to tick off?",
    "If you had a time machine, would you go to the past or the future?",
    "What's your go-to comfort food?",
    "What's the best gift you've ever given someone?",
    "If you could be any animal for a day, what would you be?",
    "What was the last thing you read that really moved you?",
    "If you could master one instrument instantly, what would it be?",
    "What is the most memorable prank you've ever pulled or had pulled on you?",
    "What's a fact you learned recently that blew your mind?",
    "If you could be any fictional character's best friend, who would it be?",
    "Which language would you love to learn to speak fluently?",
    "What is a childhood rule you still follow today?",
    "What's the weirdest food combo that you secretly enjoy?",
    "Do you believe in aliens? Why or why not?",
    "What's the most beautiful place you've ever seen in person?",
    "If you were stranded on a desert island, what 3 physical objects would you bring?",
    "What was your favorite childhood toy?",
    "If you had to describe yourself in 3 words, what would they be?",
    "What's the best concert you've ever been to?",
    "If you could have any job in the world without worrying about money, what would it be?",
    "What's a small thing that instantly makes your day better?",
    "Are you a morning person or a night owl?",
    "What is the most irrational fear you have?",
    "What's the most daring thing you've ever done?",
    "If you could be guaranteed the correct answer to one question, what would you ask?",
    "What's a skill you'd like to learn but haven't had the time for?",
    "If you could only listen to one album for the rest of your life, what would it be?",
    "What is the best compliment you've ever received?",
    "If you had to switch lives with someone for a day, who would it be?",
    "What’s the most unforgettable lesson you’ve learned from a mistake?",
    "If you could write a book, what would it be about?",
    "What’s your favorite quote and why?",
    "If you could invent a new holiday, what would we celebrate?",
    "What was the highlight of your week so far?",
    "If your house was on fire and you could only save one item, what would it be?",
    "What’s the most interesting documentary you’ve ever watched?",
    "If you were a color, what color would you be and why?",
    "What’s a trend from the past that you wish would come back?",
    "If you could have a conversation with your future self, what would you ask?",
    "What is the most adventurous thing on your bucket list?",
    "What’s the strangest coincidence that’s ever happened to you?",
    "If you had to listen to one artist for a whole year, who would it be?",
    "What’s your favorite word in the English language?",
    "If you could relive one day of your life, which day would it be?",
    "What is a cause you are deeply passionate about?",
    "If you could design your dream home, what’s one room it absolutely must have?",
    "What’s a movie that practically everyone loves but you secretly dislike?",
    "If you could be a contestant on any game show, which one would it be?",
    "What’s the best piece of advice you would give to your younger self?",
    "What is the most surprising thing you’ve learned about yourself recently?",
    "If you could teleport to any specific moment in history, when and where would you go?",
    "What’s your favorite way to relax after a long day?",
    "If you had an unlimited budget to start a business, what would it be?",
    "What is a simple pleasure that you never take for granted?",
    "If you could star in any movie, what kind of character would you play?",
    "What’s the most memorable meal you’ve ever eaten?",
    "If you had to teach a class on one obscure subject, what would it be?",
    "What’s a popular song that you can’t stand?",
    "If you could have any exotic pet, what would you choose?",
    "What is the best way someone can show they care about you?",
    "If you could magically eliminate one minor inconvenience from your life, what would it be?",
    "What’s the funniest joke you know by heart?",
    "If you were given a million dollars but had to give it all away, who would you give it to?",
    "What’s the best season of the year and why?",
    "If you could automatically be hired for your dream job, what would the title be?",
    "What is the most important quality you look for in a friend?",
    "If your pet could talk for one minute, what do you think they would say?",
    "What’s the most unusual place you’ve ever slept?",
    "If you could magically learn to cook one elaborate dish perfectly, what would it be?",
    "What’s the bravest thing you’ve ever done?",
    "If you were trapped in a TV show for a month, which show would it be?",
    "What is the best advice you’ve ever ignored?",
    "If you could change one thing about the way you were raised, what would it be?",
    "What is the most defining moment of your life so far?",
    "If you could only use 3 apps on your phone, what would they be?",
    "What’s your favorite tradition from your childhood?",
    "If you were a ghost, who or where would you haunt?",
    "What is a book that completely changed your perspective on life?",
    "If you could invent a new flavor of ice cream, what would it be?",
    "What’s the scariest thing you’ve ever done for fun?",
    "If you could have a lifetime supply of one item, what would it be?",
    "What is a topic you could give a 30-minute presentation on with zero preparation?",
    "If you could permanently erase one chore from your life, what would you pick?",
    "What’s your biggest pet peeve?",
    "If you could instantly upgrade one piece of technology you own, what would it be?",
    "What’s the best compliment you’ve ever given someone else?",
    "If you could only eat cuisine from one country for the rest of your life, which would it be?",
    "What’s a personal rule you never break?",
    "If you could experience one fictional event in real life, what would it be?",
    "What’s the most embarrassing phase you went through?",
    "If you could be remembered for one specific accomplishment, what would you want it to be?",
    "What’s the happiest memory you have?",
    "If you had the power to change one law in your country, what would you change?",
    "What’s your favorite smell in the whole world?",
    "If you could have your own personal billboard, what would it say?",
    "What’s the most thoughtful thing anyone has ever done for you?",
    "If you were given an extra hour every day, what would you use it for?",
    "What’s your favorite sound?",
    "If you could seamlessly blend into any culture, which one would you choose to experience?",
    "What's the hardest thing you've ever had to achieve?",
    "If you were to write a movie script, what would it be about?",
    "What part of your daily routine do you enjoy the most?",
    "If you had to live in a different state or country, where would you go?",
    "What’s an unpopular opinion you hold?",
    "If you were stuck on an elevator with one person for 12 hours, who would you want it to be?",
  ];

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
        data,
      ) {
        if (data != null) {
          setState(() {
            _xp = data['xp'] ?? 0;
            String newLevel = _calculateLevel(_xp);

            if (!_isFirstLoad &&
                _relationshipLevel != newLevel &&
                newLevel == 'Soulmate') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
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
              });
            }

            _relationshipLevel = newLevel;
            _isFirstLoad = false;
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
                        currentUserId: _currentUserId,
                        chatId: _chatId,
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
                    onPressed: _sendIcebreaker,
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
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Text('✌️', style: TextStyle(fontSize: 16)),
                    label: const Text('Play RPS'),
                    onPressed: _sendRandomRpsChallenge,
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                    labelStyle: const TextStyle(
                      color: Colors.blue,
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
                      onSubmitted: _sendMessage,
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

  Future<void> _sendIcebreaker() async {
    final history = await _databaseService.getMessageHistory(
      _chatId,
      limit: 10000,
    );
    final sentTexts = history.map((m) => m.text).toSet();

    final unusedIcebreakers = _icebreakers
        .where((i) => !sentTexts.contains(i))
        .toList();

    if (unusedIcebreakers.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You've used all available icebreakers!"),
          ),
        );
      }
      return;
    }

    unusedIcebreakers.shuffle();
    final randomStr = unusedIcebreakers.first;
    _sendMessage(randomStr);
  }

  Future<void> _sendMessage(String text) async {
    await _sendMessageInternal(text, saveToDb: true);
  }

  Future<void> _sendMessageInternal(
    String text, {
    required bool saveToDb,
  }) async {
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
    if (saveToDb) {
      _controller.clear();
    }

    // Create User Message
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      senderId: _currentUserId,
      text: userMessageText,
      timestamp: DateTime.now(),
    );

    // Save to Database only if requested
    if (saveToDb) {
      await _databaseService.sendMessage(_chatId, userMessage);
    }

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
    apiMessages.add(
      DatingPersona.generateFor(
        widget.user,
        currentUser,
        relationshipLevel: _relationshipLevel,
      ),
    );

    // 2. Fetch recent context (save tokens: use last 5 instead of 20)
    try {
      final history = await _databaseService.getMessageHistory(
        _chatId,
        limit: 5,
      );
      // History is descending (newest first), but API needs ascending (oldest first)
      // Reverse it
      for (var msg in history.reversed) {
        // Exclude the message we just sent if it appears in history (to avoid duplication)
        if (msg.id == userMessage.id) continue;

        apiMessages.add({
          'role': msg.senderId == _currentUserId ? 'user' : 'assistant',
          'content': msg.text,
        });
      }
    } catch (e) {
      debugPrint("Could not fetch history: $e");
    }

    // 3. Add Current Message (it might not be in the history fetch yet due to race/delay)
    // 3. Add Current Message (it might not be in the history fetch yet due to race/delay)
    // We explicitly add it to ensure the AI sees it as the *latest* prompt.
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

  void _showStickerPicker(BuildContext context) {
    // A curated list of lovely sticker URLs with descriptive names for the AI
    final List<Map<String, String>> stickerData = [
      {
        'url':
            'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExMmVtdWd5YmlyZHdrcTBpeWVib2k2cDB6OTJqdDJnZndhY2hheDcyMSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/11S5TjEEDEq8t126uYn/giphy.gif',
        'desc': 'a spinning animated heart',
      },
      {
        'url':
            'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExbDVtc2Vqa3RocWtlaGczMWE0NmxlaXRnODJ4cjdwd2YxcTJlaDUzMyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/26FLdmIp6wJr91JAI/giphy.gif',
        'desc': 'an adorable cat cuddling and hugging a heart affectionately',
      },
      {
        'url':
            'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExcGxtZmxhNjZpdHJmMGExdXpnd3J5NXB2NzR6ZGNsbnAxdXR1dWF6bCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/MDJ9IbxxvDUQM/giphy.gif',
        'desc': 'a cute cat stretching its arms out to give a big warm hug',
      },
      {
        'url':
            'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExenF2emtxMzFxdXV6MzhpdGVldXZvcGV0MWtiam9uYnJwNXgyYXB6eSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/l4pTfx2qLszoacZRS/giphy.gif',
        'desc': 'shining, magical sparkles indicating awe or excitement',
      },
      {
        'url':
            'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExdXQyOHE0bHExdGpnZW94YnRvdGR0NGQ3am9nZG13amIzejdmaGQwZiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/3o7TKoWXm3okO1kgHC/giphy.gif',
        'desc': 'a small dog dancing happily and playfully',
      },
      {
        'url':
            'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExcm5nZHB0ZXFtaDFhMmhtdnhrNXVxc2NueHpvamZ1eDJucDNsOTNnbyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/7kn27lnYSAE9O/giphy.gif',
        'desc': 'a cute dog laughing hysterically on the floor',
      },
      {
        'url':
            'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNmNxdmQ3dDhybjFmOHp3anl6aDdzZWYxaTN1Mm13ZGg5NnB4eXZpdSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/R6gvnAxj2ISzJdbA63/giphy.gif',
        'desc': 'a sad, crying animal shedding tears',
      },
      {
        'url':
            'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExYzlqMDhzMjdzeWR5dzc0ejhmcTVyNm5yeWFzbnF3enlxMWg0a24weiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/KztT2c4u8mYYUiMKdJ/giphy.gif',
        'desc': 'blowing an animated kiss full of love',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 300,
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
                        _sendSticker(sticker['url']!, sticker['desc']!);
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ImageUtils.getImageWidget(
                          sticker['url']!,
                          fit: BoxFit.cover,
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

  Future<void> _sendSticker(String stickerUrl, String description) async {
    final currentUser = Provider.of<UserProvider>(
      context,
      listen: false,
    ).currentUser;

    if (currentUser == null) return;

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      senderId: _currentUserId,
      text: 'Sent a sticker',
      timestamp: DateTime.now(),
      stickerUrl: stickerUrl,
    );

    // Save to Database
    await _databaseService.sendMessage(_chatId, userMessage);

    // Treat as a regular message to the AI but explicitly describe the sticker WITHOUT displaying it as a new chat bubble
    _sendMessageInternal(
      '[User sent a sticker of $description]',
      saveToDb: false,
    );
  }

  void _sendRandomRpsChallenge() {
    final moves = ['rock', 'paper', 'scissors'];
    moves.shuffle();
    final userMove = moves.first;
    _sendRpsChallenge(userMove);
  }

  Future<void> _sendRpsChallenge(String move) async {
    final currentUser = Provider.of<UserProvider>(
      context,
      listen: false,
    ).currentUser;

    if (currentUser == null) return;

    final gameData = {
      'challengerId': _currentUserId,
      'challengerMove': move,
      'opponentId': widget.user.id,
      'opponentMove': null,
      'status': 'pending',
    };

    final gameMessage = ChatMessage(
      id: _uuid.v4(),
      senderId: _currentUserId,
      text: 'I challenged you to Rock, Paper, Scissors!',
      timestamp: DateTime.now(),
      gameType: 'rps',
      gameData: gameData,
    );

    try {
      await _databaseService.sendMessage(_chatId, gameMessage);

      // Auto-reply so the AI doesn't try to reply to the game move as if it's chat text
      // All matches in this environment are AI implementations
      _simulateAiRpsResponse(gameMessage);
    } catch (e) {
      debugPrint("Error sending RPS challenge: $e");
    }
  }

  // Very simple bot logic so the AI can play back automatically
  Future<void> _simulateAiRpsResponse(ChatMessage initialMessage) async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final moves = ['rock', 'paper', 'scissors'];
    moves.shuffle();
    final botMove = moves.first;

    final gameData = Map<String, dynamic>.from(initialMessage.gameData ?? {});
    gameData['opponentMove'] = botMove;
    gameData['status'] = 'completed';

    await _databaseService.updateGameMessage(
      _chatId,
      initialMessage.id,
      gameData,
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
    if (message.gameType == 'rps') {
      return RepaintBoundary(
        child: RpsGameBubble(
          message: message,
          isMe: isMe,
          currentUserId: currentUserId,
          chatId: chatId,
          databaseService: databaseService,
        ),
      );
    }

    if (message.stickerUrl != null && message.stickerUrl!.isNotEmpty) {
      return RepaintBoundary(
        child: Align(
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
        ),
      );
    }

    return RepaintBoundary(
      child: Align(
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

class RpsGameBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final String currentUserId;
  final String chatId;
  final DatabaseService databaseService;

  const RpsGameBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.currentUserId,
    required this.chatId,
    required this.databaseService,
  });

  String _getEmoji(String? move) {
    if (move == 'rock') return '🪨';
    if (move == 'paper') return '📄';
    if (move == 'scissors') return '✂️';
    return '❓';
  }

  String _getGameResult(String myMove, String theirMove) {
    if (myMove == theirMove) return 'It\'s a Tie!';
    if ((myMove == 'rock' && theirMove == 'scissors') ||
        (myMove == 'paper' && theirMove == 'rock') ||
        (myMove == 'scissors' && theirMove == 'paper')) {
      return 'You Won! 🎉';
    }
    return 'You Lost! 😢';
  }

  @override
  Widget build(BuildContext context) {
    final gameData = message.gameData ?? {};
    final status = gameData['status'] as String? ?? 'pending';
    final challengerId = gameData['challengerId'] as String?;
    final challengerMove = gameData['challengerMove'] as String?;
    final opponentMove = gameData['opponentMove'] as String?;

    final iAmChallenger = currentUserId == challengerId;

    Widget content;

    if (status == 'pending') {
      if (iAmChallenger) {
        content = Column(
          children: [
            const Text(
              'You challenged them to Rock, Paper, Scissors!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Waiting for their move...',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            Text(
              'Your move: ${_getEmoji(challengerMove)}',
              style: const TextStyle(fontSize: 24),
            ),
          ],
        );
      } else {
        content = Column(
          children: [
            const Text(
              'You were challenged to Rock, Paper, Scissors!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Pick your move:'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMoveButton('rock', '🪨'),
                _buildMoveButton('paper', '📄'),
                _buildMoveButton('scissors', '✂️'),
              ],
            ),
          ],
        );
      }
    } else {
      // Completed
      final myMove = iAmChallenger ? challengerMove : opponentMove;
      final theirMove = iAmChallenger ? opponentMove : challengerMove;

      content = Column(
        children: [
          const Text(
            'Rock, Paper, Scissors Result',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  const Text('You'),
                  Text(_getEmoji(myMove), style: const TextStyle(fontSize: 32)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'VS',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Column(
                children: [
                  const Text('Them'),
                  Text(
                    _getEmoji(theirMove),
                    style: const TextStyle(fontSize: 32),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getGameResult(myMove!, theirMove!),
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFFFE3C72),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFE3C72).withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: content,
      ),
    );
  }

  Widget _buildMoveButton(String move, String emoji) {
    return InkWell(
      onTap: () async {
        final gameData = Map<String, dynamic>.from(message.gameData ?? {});
        gameData['opponentMove'] = move;
        gameData['status'] = 'completed';
        await databaseService.updateGameMessage(chatId, message.id, gameData);
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}
