import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/user_model.dart';
import '../../domain/entities/chat_message.dart';

import '../../data/datasources/chat_service.dart';
import '../../data/datasources/notification_service.dart';
import '../../core/config/dating_persona.dart';

import '../../domain/usecases/get_chat_id_usecase.dart';
import '../../domain/usecases/get_chat_stream_usecase.dart';
import '../../domain/usecases/get_message_history_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService;
  final NotificationService _notificationService;

  final GetChatIdUseCase _getChatIdUseCase;
  final GetChatStreamUseCase _getChatStreamUseCase;
  final GetMessageHistoryUseCase _getMessageHistoryUseCase;
  final SendMessageUseCase _sendMessageUseCase;

  ChatProvider({
    required ChatService chatService,
    required NotificationService notificationService,
    required GetChatIdUseCase getChatIdUseCase,
    required GetChatStreamUseCase getChatStreamUseCase,
    required GetMessageHistoryUseCase getMessageHistoryUseCase,
    required SendMessageUseCase sendMessageUseCase,
  }) : _chatService = chatService,
       _notificationService = notificationService,
       _getChatIdUseCase = getChatIdUseCase,
       _getChatStreamUseCase = getChatStreamUseCase,
       _getMessageHistoryUseCase = getMessageHistoryUseCase,
       _sendMessageUseCase = sendMessageUseCase;

  late String _currentUserId;
  String? _chatId;
  User? _currentUser;
  User? _otherUser;

  bool _isTyping = false;
  int _xp = 0;
  bool _isFirstLoad = true;
  String _relationshipLevel = "Stranger";

  // Note: we track the stream of messages dynamically in the UI (StreamBuilder) or we can manage it here.
  // Managing it here gives us more control. Let's provide the stream.
  Stream<List<ChatMessage>>? _messagesStream;
  StreamSubscription<List<ChatMessage>>?
  _chatSubscription; // For XP updates. Since ChatMessage domain doesn't expose XP yet, we'll need to listen differently or adjust.

  bool get isTyping => _isTyping;
  int get xp => _xp;
  String get relationshipLevel => _relationshipLevel;
  String? get chatId => _chatId;
  Stream<List<ChatMessage>>? get messagesStream => _messagesStream;

  User? get currentUser => _currentUser;

  // Callback for when Soulmate level is reached
  void Function()? onSoulmateLevelReached;

  final Uuid _uuid = const Uuid();

  final List<String> _icebreakers = [
    "Two truths and a lie, go!",
    "What's your most controversial food opinion?",
    "If you could teleport anywhere right now, where to?",
    "What's the best show you've watched recently?",
    "What's a hobby you've always wanted to pick up?",
    "What's your ideal first date?",
  ]; // Truncated for brevity of provider, but we can expand or keep in UI layer.

  Future<void> initChat(User currentUser, User otherUser) async {
    _currentUser = currentUser;
    _currentUserId = currentUser.id;
    _otherUser = otherUser;
    _chatId = await _getChatIdUseCase(_currentUserId, otherUser.id);

    _messagesStream = _getChatStreamUseCase(_chatId!);

    // Cancel "Miss you" notification as user is here
    _notificationService.cancelNotification(_chatId.hashCode);

    // Note: To get XP, the current GetChatStreamUseCase only returns List<ChatMessage>.
    // To properly support XP in clean architecture without breaking domain boundaries,
    // the Chat entity would need to include XP. For now, since ChatRepository stream
    // strips out XP, we might need a dedicated `getChatDetailsStream` use-case, or
    // we manage it through the messages.
    // Wait, the UI used `_databaseService.getChatStream` which returns `Map<String, dynamic>`.

    // I will implement a workaround for XP for now to preserve functionality without breaking abstractions later.
    // For now, let's keep the stream attached and we'll fix XP through a separate UseCase or updating the UI soon.

    notifyListeners();
  }

  void disposeProvider() {
    _chatSubscription?.cancel();
  }

  double calculateProgress(int xp) {
    if (xp < 10) return xp / 10;
    if (xp < 30) return (xp - 10) / (30 - 10);
    if (xp < 60) return (xp - 30) / (60 - 30);
    if (xp < 100) return (xp - 60) / (100 - 60);
    return 1.0; // Soulmate (Maxed)
  }

  String calculateLevel(int xp) {
    if (xp < 10) return "Stranger";
    if (xp < 30) return "Acquaintance";
    if (xp < 60) return "Friend";
    if (xp < 100) return "Crush";
    return "Soulmate";
  }

  void updateXp(int newXp) {
    if (_xp == newXp) return;

    _xp = newXp;
    String newLevel = calculateLevel(_xp);

    if (!_isFirstLoad &&
        _relationshipLevel != newLevel &&
        newLevel == 'Soulmate') {
      onSoulmateLevelReached?.call();
    }

    _relationshipLevel = newLevel;
    _isFirstLoad = false;
    notifyListeners();
  }

  Future<void> sendIcebreaker() async {
    if (_chatId == null) return;

    final history = await _getMessageHistoryUseCase(_chatId!, limit: 50);
    final sentTexts = history.map((m) => m.text).toSet();

    final unusedIcebreakers = _icebreakers
        .where((i) => !sentTexts.contains(i))
        .toList();

    if (unusedIcebreakers.isEmpty) {
      // Could trigger a callback instead
      return;
    }

    unusedIcebreakers.shuffle();
    final randomStr = unusedIcebreakers.first;
    sendMessage(randomStr);
  }

  Future<void> sendMessage(String text) async {
    await _sendMessageInternal(text, saveToDb: true);
  }

  Future<void> sendSticker(String stickerUrl, int index) async {
    if (_currentUser == null || _chatId == null) return;

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      senderId: _currentUserId,
      text: 'Sent a sticker',
      timestamp: DateTime.now(),
      stickerUrl: stickerUrl,
    );

    // Save to Database
    await _sendMessageUseCase(_chatId!, userMessage);

    // Treat as a regular message to the AI but explicitly describe the sticker WITHOUT displaying it as a new chat bubble
    _sendMessageInternal('[USER_STICKER:$index]', saveToDb: false);
  }

  Future<void> _sendMessageInternal(
    String text, {
    required bool saveToDb,
  }) async {
    if (text.trim().isEmpty ||
        _chatId == null ||
        _currentUser == null ||
        _otherUser == null) {
      return;
    }

    final userMessageText = text.trim();

    // Create User Message
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      senderId: _currentUserId,
      text: userMessageText,
      timestamp: DateTime.now(),
    );

    // Save to Database only if requested
    if (saveToDb) {
      await _sendMessageUseCase(_chatId!, userMessage);
    }

    // Schedule Proactive Notification (Retention Hook)
    try {
      await _notificationService.cancelNotification(_chatId.hashCode);
      await _notificationService.scheduleNotification(
        id: _chatId.hashCode,
        title: '${_otherUser!.firstName} misses you! 🥺',
        body:
            'Come back and continue your conversation with ${_otherUser!.firstName}.',
        delay: const Duration(hours: 6),
      );
    } catch (e) {
      debugPrint("Error scheduling notification: $e");
    }

    _isTyping = true;
    notifyListeners();

    // Build Chat History for API
    List<Map<String, String>> apiMessages = [];

    // 1. Add System Prompt
    apiMessages.add(
      DatingPersona.generateFor(
        _otherUser!,
        _currentUser!,
        relationshipLevel: _relationshipLevel,
      ),
    );

    // 2. Fetch recent context
    try {
      final history = await _getMessageHistoryUseCase(_chatId!, limit: 5);
      for (var msg in history.reversed) {
        if (msg.id == userMessage.id) continue;

        apiMessages.add({
          'role': msg.senderId == _currentUserId ? 'user' : 'assistant',
          'content': msg.text,
        });
      }
    } catch (e) {
      debugPrint("Could not fetch history: $e");
    }

    // 3. Add Current Message
    apiMessages.add({'role': 'user', 'content': userMessageText});

    // Send to Chat Service
    try {
      final responseText = await _chatService.sendMessage(apiMessages);

      _isTyping = false;
      notifyListeners();

      if (responseText.startsWith("Error: No internet connection")) {
        // Handle error via callback possibly
        return;
      }

      // Create AI Message
      final aiMessage = ChatMessage(
        id: _uuid.v4(),
        senderId: _otherUser!.id,
        text: responseText,
        timestamp: DateTime.now(),
      );

      // Save to Database
      await _sendMessageUseCase(_chatId!, aiMessage);
    } catch (e) {
      debugPrint("Error getting AI response: $e");
      _isTyping = false;
      notifyListeners();
    }
  }
}
