import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/user.dart';
import '../../domain/entities/chat_message.dart';

import '../../domain/repositories/ai_chat_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../core/config/dating_persona.dart';

import '../../domain/usecases/get_chat_id_usecase.dart';
import '../../domain/usecases/get_chat_stream_usecase.dart';
import '../../domain/usecases/get_message_history_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/mark_messages_as_read_usecase.dart';
import '../../domain/usecases/send_ai_message_usecase.dart';
import '../../domain/usecases/get_chat_metadata_stream_usecase.dart';

class ChatProvider extends ChangeNotifier {
  // ignore: unused_field — reserved for future direct repository operations
  final AiChatRepository _aiChatRepository;
  final NotificationRepository _notificationRepository;

  final GetChatIdUseCase _getChatIdUseCase;
  final GetChatStreamUseCase _getChatStreamUseCase;
  final GetMessageHistoryUseCase _getMessageHistoryUseCase;
  final SendMessageUseCase _sendMessageUseCase;
  final MarkMessagesAsReadUseCase _markMessagesAsReadUseCase;
  final SendAiMessageUseCase _sendAiMessageUseCase;
  final GetChatMetadataStreamUseCase _getChatMetadataStreamUseCase;

  ChatProvider({
    required AiChatRepository aiChatRepository,
    required NotificationRepository notificationRepository,
    required GetChatIdUseCase getChatIdUseCase,
    required GetChatStreamUseCase getChatStreamUseCase,
    required GetMessageHistoryUseCase getMessageHistoryUseCase,
    required SendMessageUseCase sendMessageUseCase,
    required MarkMessagesAsReadUseCase markMessagesAsReadUseCase,
    required SendAiMessageUseCase sendAiMessageUseCase,
    required GetChatMetadataStreamUseCase getChatMetadataStreamUseCase,
  }) : _aiChatRepository = aiChatRepository,
       _notificationRepository = notificationRepository,
       _getChatIdUseCase = getChatIdUseCase,
       _getChatStreamUseCase = getChatStreamUseCase,
       _getMessageHistoryUseCase = getMessageHistoryUseCase,
       _sendMessageUseCase = sendMessageUseCase,
       _markMessagesAsReadUseCase = markMessagesAsReadUseCase,
       _sendAiMessageUseCase = sendAiMessageUseCase,
       _getChatMetadataStreamUseCase = getChatMetadataStreamUseCase;

  late String _currentUserId;
  String? _chatId;
  User? _currentUser;
  User? _otherUser;

  bool _isTyping = false;
  int _xp = 0;
  bool _isFirstLoad = true;
  String _relationshipLevel = "Stranger";

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _disposed = false;

  StreamSubscription<List<ChatMessage>>? _chatSubscription;
  StreamSubscription<Map<String, dynamic>?>? _metadataSubscription;

  bool get isTyping => _isTyping;
  int get xp => _xp;
  String get relationshipLevel => _relationshipLevel;
  String? get chatId => _chatId;
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

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
  ]; 

  Future<void> initChat(User currentUser, User otherUser) async {
    _disposed = false; // Reset in case provider is being reused
    final newChatId = await _getChatIdUseCase(currentUser.id, otherUser.id);

    // Skip re-init if already listening to this chat
    if (_chatId == newChatId && _currentUser?.id == currentUser.id) {
      if (_isLoading) {
        _isLoading = false;
        _safeNotifyListeners();
      }
      return;
    }

    // Clean up previous state if any
    await _chatSubscription?.cancel();
    await _metadataSubscription?.cancel();

    _currentUser = currentUser;
    _currentUserId = currentUser.id;
    _otherUser = otherUser;
    _chatId = newChatId;
    _isLoading = true;
    _messages = [];
    _safeNotifyListeners();

    // Mark incoming messages as read
    _markMessagesAsReadUseCase(_chatId!, _currentUserId);

    // Listen to messages
    _chatSubscription = _getChatStreamUseCase(_chatId!).listen((messages) {
      _messages = messages;
      _isLoading = false;
      _safeNotifyListeners();
    }, onError: (error) {
      debugPrint("Chat Stream Error: $error");
      _isLoading = false;
      _safeNotifyListeners();
    });

    // Cancel "Miss you" notification as user is here
    _notificationRepository.cancelNotification(_chatId.hashCode);

    // Listen to metadata for real-time XP changes
    _metadataSubscription = _getChatMetadataStreamUseCase(_chatId!).listen((
      metadata,
    ) {
      if (metadata != null && metadata.containsKey('xp')) {
        updateXp(metadata['xp'] as int);
      }
    }, onError: (error) {
      debugPrint("Metadata Stream Error: $error");
    });
  }

  void clearChatData() {
    _chatSubscription?.cancel();
    _chatSubscription = null;
    _metadataSubscription?.cancel();
    _metadataSubscription = null;
    _chatId = null;
    _currentUser = null;
    _otherUser = null;
    _isTyping = false;
    _xp = 0;
    _isFirstLoad = true;
    _relationshipLevel = "Stranger";
    _messages = [];
    _isLoading = true;
    onSoulmateLevelReached = null;
  }

  /// Safe wrapper that skips notification if provider has been disposed.
  void _safeNotifyListeners() {
    if (!_disposed) notifyListeners();
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
    _safeNotifyListeners();
  }

  Future<void> sendIcebreaker() async {
    if (_chatId == null) return;

    final history = await _getMessageHistoryUseCase(_chatId!, limit: 50);
    // Micro-optimization: Use collection for-loop to build the Set directly without an intermediate Iterable
    final sentTexts = {for (var m in history) m.text};

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

      // Schedule Proactive Notification only for user-sent messages
      try {
        await _notificationRepository.cancelNotification(_chatId.hashCode);
        await _notificationRepository.scheduleNotification(
          id: _chatId.hashCode,
          title: '${_otherUser!.firstName} misses you! 🥺',
          body:
              'Come back and continue your conversation with ${_otherUser!.firstName}.',
          delay: const Duration(hours: 6),
        );
      } catch (e) {
        debugPrint("Error scheduling notification: $e");
      }
    }

    _isTyping = true;
    _safeNotifyListeners();

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
      final responseText = await _sendAiMessageUseCase(apiMessages);

      _isTyping = false;
      _safeNotifyListeners();

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
      _safeNotifyListeners();

      if (e.toString().contains("RATE_LIMIT")) {
        return;
      }

      // Inject an AI-sent error message payload into the db instead of failing silently
      final aiMessage = ChatMessage(
        id: _uuid.v4(),
        senderId: _otherUser!.id,
        text: "I'm having a hard time connecting right now. Let's chat later!",
        timestamp: DateTime.now(),
      );
      await _sendMessageUseCase(_chatId!, aiMessage);
    }
  }
}
