import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/chat_message.dart';
import '../models/chat_message_model.dart';

/// Handles all chat/message operations using secure local storage.
class ChatDatabaseService {
  final FlutterSecureStorage _secureStorage;

  // Local Streams for chat data
  final Map<String, StreamController<Map<String, dynamic>?>>
  _chatStreamControllers = {};
  final Map<String, StreamController<List<ChatMessage>>>
  _messageStreamControllers = {};

  ChatDatabaseService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Generate a deterministic chat ID from two user IDs.
  String getChatId(String userId1, String userId2) {
    return userId1.hashCode <= userId2.hashCode
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
  }

  /// Get active chats for a user.
  Future<List<Map<String, dynamic>>> getActiveChats(String userId) async {
    try {
      final chatsJson =
          await _secureStorage.read(key: 'chats_metadata') ?? '{}';
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
    try {
      // Save Message
      final messagesKey = 'chat_messages_$chatId';
      final msgsStr = await _secureStorage.read(key: messagesKey);
      List<String> messagesJson = msgsStr != null
          ? List<String>.from(jsonDecode(msgsStr))
          : [];

      final msgMap = ChatMessageModel.fromEntity(message).toMap();
      msgMap['id'] = message.id; // Include ID in map for local storage
      messagesJson.insert(
        0,
        jsonEncode(msgMap),
      ); // Store newest first to match descending order
      await _secureStorage.write(
        key: messagesKey,
        value: jsonEncode(messagesJson),
      );

      // Update Stream
      _broadcastMessages(chatId);

      // Update Metadata
      final chatsJson =
          await _secureStorage.read(key: 'chats_metadata') ?? '{}';
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
        'participants': chatId.split('_'),
        'xp': currentXp + 1,
        'streak': currentStreak,
      };

      allChats[chatId] = updatedData;
      await _secureStorage.write(
        key: 'chats_metadata',
        value: jsonEncode(allChats),
      );

      // Broadcast Metadata change
      _broadcastChatMetadata(chatId, updatedData);
    } catch (e) {
      debugPrint("Error sending message: $e");
      rethrow;
    }
  }

  /// Update game data on a specific message.
  Future<void> updateGameMessage(
    String chatId,
    String messageId,
    Map<String, dynamic> gameData,
  ) async {
    try {
      final messagesKey = 'chat_messages_$chatId';
      final msgsStr = await _secureStorage.read(key: messagesKey);
      List<String> messagesJson = msgsStr != null
          ? List<String>.from(jsonDecode(msgsStr))
          : [];

      for (int i = 0; i < messagesJson.length; i++) {
        final Map<String, dynamic> msgMap = jsonDecode(messagesJson[i]);
        if (msgMap['id'] == messageId) {
          msgMap['gameData'] = gameData;
          messagesJson[i] = jsonEncode(msgMap);
          break;
        }
      }

      await _secureStorage.write(
        key: messagesKey,
        value: jsonEncode(messagesJson),
      );
      _broadcastMessages(chatId);
    } catch (e) {
      debugPrint("Error updating game message: $e");
      rethrow;
    }
  }

  /// Get a stream of chat metadata changes.
  Stream<Map<String, dynamic>?> getChatStream(String chatId) {
    if (!_chatStreamControllers.containsKey(chatId)) {
      _chatStreamControllers[chatId] =
          StreamController<Map<String, dynamic>?>.broadcast();
    }

    // Send initial value
    _secureStorage.read(key: 'chats_metadata').then((chatsJson) {
      final Map<String, dynamic> allChats = jsonDecode(chatsJson ?? '{}');
      _chatStreamControllers[chatId]!.add(
        allChats[chatId] as Map<String, dynamic>?,
      );
    });

    return _chatStreamControllers[chatId]!.stream;
  }

  /// Get a stream of messages for a chat.
  Stream<List<ChatMessage>> getMessages(String chatId) {
    if (!_messageStreamControllers.containsKey(chatId)) {
      _messageStreamControllers[chatId] =
          StreamController<List<ChatMessage>>.broadcast();
    }

    // Broadcast initial history
    _broadcastMessages(chatId);

    return _messageStreamControllers[chatId]!.stream;
  }

  /// Get recent message history for a chat.
  Future<List<ChatMessage>> getMessageHistory(
    String chatId, {
    int limit = 10,
  }) async {
    try {
      final messagesKey = 'chat_messages_$chatId';
      final msgsStr = await _secureStorage.read(key: messagesKey);
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
    try {
      // Delete messages
      await _secureStorage.delete(key: 'chat_messages_$chatId');

      // Delete metadata
      final chatsJson =
          await _secureStorage.read(key: 'chats_metadata') ?? '{}';
      final Map<String, dynamic> allChats = jsonDecode(chatsJson);
      if (allChats.containsKey(chatId)) {
        allChats.remove(chatId);
        await _secureStorage.write(
          key: 'chats_metadata',
          value: jsonEncode(allChats),
        );
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
  }

  /// Mark messages from the other user as read.
  Future<void> markMessagesAsRead(String chatId, String currentUserId) async {
    try {
      final messagesKey = 'chat_messages_$chatId';
      final msgsStr = await _secureStorage.read(key: messagesKey);
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
        await _secureStorage.write(
          key: messagesKey,
          value: jsonEncode(messagesJson),
        );
        _broadcastMessages(chatId);
      }
    } catch (e) {
      debugPrint("Error marking messages as read: $e");
    }
  }

  /// Delete all chat data from secure storage.
  Future<void> deleteAllChats() async {
    final chatsJson = await _secureStorage.read(key: 'chats_metadata') ?? '{}';
    final Map<String, dynamic> allChats = jsonDecode(chatsJson);

    for (var chatId in allChats.keys) {
      await deleteChat(chatId);
    }
  }

  // --- Private helpers ---

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
