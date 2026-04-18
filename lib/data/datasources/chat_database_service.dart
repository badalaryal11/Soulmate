import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/chat_message.dart';
import '../models/chat_message_model.dart';

/// A simple asynchronous mutex to serialize operations.
class _SimpleMutex {
  Future<void>? _lastOperation;

  Future<T> synchronized<T>(Future<T> Function() action) async {
    final previousOperation = _lastOperation;
    final completer = Completer<void>();
    _lastOperation = completer.future;

    if (previousOperation != null) {
      await previousOperation;
    }

    try {
      return await action();
    } finally {
      completer.complete();
    }
  }
}

/// Handles all chat/message operations using secure local storage.
class ChatDatabaseService {
  final _SimpleMutex _mutex = _SimpleMutex();

  // Local Streams for chat data
  final Map<String, StreamController<Map<String, dynamic>?>>
  _chatStreamControllers = {};
  final Map<String, StreamController<List<ChatMessage>>>
  _messageStreamControllers = {};

  ChatDatabaseService();

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  Future<String?> _safeRead(String key) async {
    try {
      final p = await _prefs;
      return p.getString(key);
    } catch (e) {
      debugPrint("SharedPreferences Read Error: $e");
      return null;
    }
  }

  Future<void> _safeWrite(String key, String value) async {
    try {
      final p = await _prefs;
      await p.setString(key, value);
    } catch (e) {
      debugPrint("SharedPreferences Write Error: $e");
    }
  }
  
  Future<void> _safeDelete(String key) async {
    try {
      final p = await _prefs;
      await p.remove(key);
    } catch (e) {
      debugPrint("SharedPreferences Delete Error: $e");
    }
  }

  /// Generate a deterministic chat ID from two user IDs.
  String getChatId(String userId1, String userId2) {
    return userId1.hashCode <= userId2.hashCode
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
  }

  /// Get active chats for a user.
  Future<List<Map<String, dynamic>>> getActiveChats(String userId) async {
    try {
      final chatsJson = await _safeRead('chats_metadata') ?? '{}';
      final Map<String, dynamic> allChats = jsonDecode(chatsJson);

      List<Map<String, dynamic>> userChats = [];
      allChats.forEach((chatId, chatData) {
        final data = chatData as Map<String, dynamic>;
        final participants = List<String>.from(data['participants'] ?? []);
        if (participants.contains(userId)) {
          data['id'] = chatId;
          userChats.add(data);
        }
      });

      userChats.sort((a, b) {
        final timeA = a['lastMessageTime'] as int? ?? 0;
        final timeB = b['lastMessageTime'] as int? ?? 0;
        return timeB.compareTo(timeA);
      });

      return userChats;
    } catch (e) {
      debugPrint("Error fetching active chats: $e");
      return [];
    }
  }

  /// Send a message to a chat.
  Future<void> sendMessage(String chatId, ChatMessage message) async {
    return _mutex.synchronized(() async {
      try {
        // Save Message
        final messagesKey = 'chat_messages_$chatId';
        final msgsStr = await _safeRead(messagesKey);
        List<String> messagesJson = msgsStr != null
            ? List<String>.from(jsonDecode(msgsStr))
            : [];

        final msgMap = ChatMessageModel.fromEntity(message).toMap();
        msgMap['id'] = message.id; // Include ID in map for local storage
        messagesJson.insert(
          0,
          jsonEncode(msgMap),
        ); // Store newest first to match descending order
        await _safeWrite(messagesKey, jsonEncode(messagesJson));

        // Broadcast the messages we already have in memory — avoids
        // re-reading SharedPreferences outside the mutex.
        _broadcastMessagesFromJson(chatId, messagesJson);

        // Update Metadata
        final chatsJson = await _safeRead('chats_metadata') ?? '{}';
        final Map<String, dynamic> allChats = jsonDecode(chatsJson);

        final chatData = allChats[chatId] as Map<String, dynamic>? ?? {};

        int currentStreak = chatData['streak'] ?? 0;
        int lastTime = chatData['lastMessageTime'] ?? 0;
        int currentXp = chatData['xp'] ?? 0;

        final now = DateTime.now();
        final lastMsgDate = DateTime.fromMillisecondsSinceEpoch(
          lastTime == 0 ? now.millisecondsSinceEpoch : lastTime,
        );
        final difference = now.difference(lastMsgDate).inHours;

        final isSameDay =
            now.year == lastMsgDate.year &&
            now.month == lastMsgDate.month &&
            now.day == lastMsgDate.day;
        final isYesterday =
            now.difference(lastMsgDate).inDays == 1 ||
            (now.day != lastMsgDate.day && difference < 48);

        if (!isSameDay && lastTime != 0) {
          if (isYesterday || currentStreak == 0) {
            currentStreak++;
          } else if (difference >= 48) {
            currentStreak = 1; // Reset
          }
        } else if (lastTime == 0) {
          currentStreak = 1;
        }

        final updatedData = {
          ...chatData,
          'lastMessage': message.text,
          'lastMessageTime': message.timestamp.millisecondsSinceEpoch,
          'participants': chatData['participants'] ?? chatId.split('_'),
          'xp': currentXp + 1,
          'streak': currentStreak,
        };

        allChats[chatId] = updatedData;
        await _safeWrite('chats_metadata', jsonEncode(allChats));

        // Broadcast Metadata change
        _broadcastChatMetadata(chatId, updatedData);
      } catch (e) {
        debugPrint("Error sending message: $e");
        rethrow;
      }
    });
  }

  /// Update game data on a specific message.
  Future<void> updateGameMessage(
    String chatId,
    String messageId,
    Map<String, dynamic> gameData,
  ) async {
    return _mutex.synchronized(() async {
      try {
        final messagesKey = 'chat_messages_$chatId';
        final msgsStr = await _safeRead(messagesKey);
        List<String> messagesJson = msgsStr != null
            ? List<String>.from(jsonDecode(msgsStr))
            : [];

        for (int i = 0; i < messagesJson.length; i++) {
          final jsonStr = messagesJson[i];
          if (jsonStr.contains('"$messageId"')) {
            final Map<String, dynamic> msgMap = jsonDecode(jsonStr);
            if (msgMap['id'] == messageId) {
              msgMap['gameData'] = gameData;
              messagesJson[i] = jsonEncode(msgMap);
              break;
            }
          }
        }

        await _safeWrite(messagesKey, jsonEncode(messagesJson));
        _broadcastMessagesFromJson(chatId, messagesJson);
      } catch (e) {
        debugPrint("Error updating game message: $e");
        rethrow;
      }
    });
  }

  /// Get a stream of chat metadata changes.
  Stream<Map<String, dynamic>?> getChatStream(String chatId) async* {
    if (!_chatStreamControllers.containsKey(chatId)) {
      late StreamController<Map<String, dynamic>?> ctrl;
      ctrl = StreamController<Map<String, dynamic>?>.broadcast(
        onCancel: () {
          ctrl.close();
          _chatStreamControllers.remove(chatId);
        },
      );
      _chatStreamControllers[chatId] = ctrl;
    }

    // Yield initial value directly to any new subscriber
    final chatsJson = await _safeRead('chats_metadata');
    final Map<String, dynamic> allChats = jsonDecode(chatsJson ?? '{}');
    yield allChats[chatId] as Map<String, dynamic>?;

    // Then delegate to the shared broadcast stream for updates
    yield* _chatStreamControllers[chatId]!.stream;
  }

  /// Get a stream of messages for a chat.
  Stream<List<ChatMessage>> getMessages(String chatId) async* {
    if (!_messageStreamControllers.containsKey(chatId)) {
      late StreamController<List<ChatMessage>> ctrl;
      ctrl = StreamController<List<ChatMessage>>.broadcast(
        onCancel: () {
          ctrl.close();
          _messageStreamControllers.remove(chatId);
        },
      );
      _messageStreamControllers[chatId] = ctrl;
    }

    // Yield current history immediately upon subscription
    yield await getMessageHistory(chatId, limit: 100);

    // Then delegate to the shared broadcast stream for updates
    yield* _messageStreamControllers[chatId]!.stream;
  }

  /// Get recent message history for a chat.
  Future<List<ChatMessage>> getMessageHistory(
    String chatId, {
    int limit = 10,
  }) async {
    try {
      final messagesKey = 'chat_messages_$chatId';
      final msgsStr = await _safeRead(messagesKey);
      List<String> messagesJson = msgsStr != null
          ? List<String>.from(jsonDecode(msgsStr))
          : [];

      final takeCount = messagesJson.length < limit
          ? messagesJson.length
          : limit;
      final recent = messagesJson.take(takeCount).map((jsonStr) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final id = map['id'] ?? '';
        return ChatMessageModel.fromMap(id, map);
      }).toList();

      return recent;
    } catch (e) {
      debugPrint("Error fetching message history: $e");
      return [];
    }
  }

  /// Delete a chat and all its messages.
  Future<void> deleteChat(String chatId) async {
    return _mutex.synchronized(() async {
      try {
        // Delete messages
        await _safeDelete('chat_messages_$chatId');

        // Delete metadata
        final chatsJson = await _safeRead('chats_metadata') ?? '{}';
        final Map<String, dynamic> allChats = jsonDecode(chatsJson);
        if (allChats.containsKey(chatId)) {
          allChats.remove(chatId);
          await _safeWrite('chats_metadata', jsonEncode(allChats));
        }

        // Close and remove stream controllers to prevent memory leaks
        if (_chatStreamControllers.containsKey(chatId)) {
          await _chatStreamControllers[chatId]!.close();
          _chatStreamControllers.remove(chatId);
        } else {
          _broadcastChatMetadata(chatId, null);
        }

        if (_messageStreamControllers.containsKey(chatId)) {
          await _messageStreamControllers[chatId]!.close();
          _messageStreamControllers.remove(chatId);
        } else {
          _broadcastMessages(chatId);
        }
      } catch (e) {
        debugPrint("Error deleting chat: $e");
        rethrow;
      }
    });
  }

  /// Mark messages from the other user as read.
  Future<void> markMessagesAsRead(String chatId, String currentUserId) async {
    return _mutex.synchronized(() async {
      try {
        final messagesKey = 'chat_messages_$chatId';
        final msgsStr = await _safeRead(messagesKey);
        if (msgsStr == null) return;

        List<String> messagesJson = List<String>.from(jsonDecode(msgsStr));
        bool changed = false;
        final now = DateTime.now().millisecondsSinceEpoch;

        for (int i = 0; i < messagesJson.length; i++) {
          final Map<String, dynamic> msgMap = jsonDecode(messagesJson[i]);
          if (msgMap['senderId'] != currentUserId && msgMap['isRead'] != true) {
            msgMap['isRead'] = true;
            msgMap['readAt'] = now;
            messagesJson[i] = jsonEncode(msgMap);
            changed = true;
          }
        }

        if (changed) {
          await _safeWrite(messagesKey, jsonEncode(messagesJson));
          _broadcastMessagesFromJson(chatId, messagesJson);
        }
      } catch (e) {
        debugPrint("Error marking messages as read: $e");
      }
    });
  }

  /// Delete all chat data from secure storage.
  Future<void> deleteAllChats() async {
    final chatsJson = await _safeRead('chats_metadata') ?? '{}';
    final Map<String, dynamic> allChats = jsonDecode(chatsJson);

    for (var chatId in allChats.keys) {
      await deleteChat(chatId);
    }
  }

  // --- Private helpers ---

  /// Broadcast from an already-loaded JSON list (avoids re-reading storage
  /// outside the mutex, which was the source of CONC-04).
  void _broadcastMessagesFromJson(String chatId, List<String> messagesJson) {
    if (_messageStreamControllers.containsKey(chatId)) {
      final messages = messagesJson.map((jsonStr) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final id = map['id'] ?? '';
        return ChatMessageModel.fromMap(id, map);
      }).toList();
      _messageStreamControllers[chatId]!.add(messages);
    }
  }

  /// Fallback for cases where we don't have the list in memory.
  void _broadcastMessages(String chatId) async {
    if (_messageStreamControllers.containsKey(chatId)) {
      final history = await getMessageHistory(chatId, limit: 100);
      _messageStreamControllers[chatId]!.add(history);
    }
  }

  void _broadcastChatMetadata(String chatId, Map<String, dynamic>? data) {
    if (_chatStreamControllers.containsKey(chatId)) {
      _chatStreamControllers[chatId]!.add(data);
    }
  }
}
