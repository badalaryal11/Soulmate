import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/chat_message.dart';
import '../models/chat_message_model.dart';

class _MergedMessageEntry {
  final String encoded;
  final int timestamp;
  final bool isRead;
  final int readAt;

  const _MergedMessageEntry({
    required this.encoded,
    required this.timestamp,
    required this.isRead,
    required this.readAt,
  });
}

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

  String _messagesKey(String chatId) => 'chat_messages_$chatId';

  String _legacyHashChatId(String userId1, String userId2) {
    return userId1.hashCode <= userId2.hashCode
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  List<String> _decodeJsonStringList(String? raw) {
    if (raw == null || raw.isEmpty) return <String>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<String>().toList();
      }
    } catch (_) {
      // Corrupt payloads are treated as empty so migration can proceed.
    }
    return <String>[];
  }

  List<String> _mergeMessageJsonLists(
    List<String> primary,
    List<String> secondary,
  ) {
    final entries = <_MergedMessageEntry>[];
    final byKey = <String, int>{};

    void addEncoded(String encoded) {
      try {
        final map = jsonDecode(encoded) as Map<String, dynamic>;
        final id = (map['id'] ?? '').toString();
        final dedupeKey = id.isNotEmpty ? 'id:$id' : 'json:$encoded';
        final timestamp = _asInt(map['timestamp']);
        final isRead = map['isRead'] == true;
        final readAt = _asInt(map['readAt']);

        final existingIndex = byKey[dedupeKey];
        if (existingIndex == null) {
          byKey[dedupeKey] = entries.length;
          entries.add(
            _MergedMessageEntry(
              encoded: encoded,
              timestamp: timestamp,
              isRead: isRead,
              readAt: readAt,
            ),
          );
          return;
        }

        final existing = entries[existingIndex];
        final shouldReplace =
            timestamp > existing.timestamp ||
            (timestamp == existing.timestamp &&
                ((isRead && !existing.isRead) || readAt > existing.readAt));
        if (shouldReplace) {
          entries[existingIndex] = _MergedMessageEntry(
            encoded: encoded,
            timestamp: timestamp,
            isRead: isRead,
            readAt: readAt,
          );
        }
      } catch (_) {
        final dedupeKey = 'json:$encoded';
        if (byKey.containsKey(dedupeKey)) return;
        byKey[dedupeKey] = entries.length;
        entries.add(
          _MergedMessageEntry(
            encoded: encoded,
            timestamp: 0,
            isRead: false,
            readAt: 0,
          ),
        );
      }
    }

    for (final encoded in primary) {
      addEncoded(encoded);
    }
    for (final encoded in secondary) {
      addEncoded(encoded);
    }

    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries.map((e) => e.encoded).toList();
  }

  Map<String, dynamic> _mergeChatMetadata({
    required Map<String, dynamic>? stableData,
    required Map<String, dynamic>? legacyData,
    required List<String> participants,
  }) {
    final stable = Map<String, dynamic>.from(stableData ?? const {});
    final legacy = Map<String, dynamic>.from(legacyData ?? const {});

    final stableTime = _asInt(stable['lastMessageTime']);
    final legacyTime = _asInt(legacy['lastMessageTime']);
    final latestTime = math.max(stableTime, legacyTime);
    final newestPayload = legacyTime > stableTime ? legacy : stable;

    return {
      ...legacy,
      ...stable,
      'participants': participants,
      'lastMessageTime': latestTime == 0 ? null : latestTime,
      'lastMessage': newestPayload['lastMessage'] ?? stable['lastMessage'],
      'xp': math.max(_asInt(stable['xp']), _asInt(legacy['xp'])),
      'streak': math.max(_asInt(stable['streak']), _asInt(legacy['streak'])),
    };
  }

  /// Generate a deterministic chat ID from two user IDs.
  String getChatId(String userId1, String userId2) {
    return userId1.compareTo(userId2) <= 0
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
        
        // Use stored participants if available, otherwise try to deduce from chatId.
        // We use a more robust check than split('_') which fails for IDs with underscores.
        List<String> participants = List<String>.from(data['participants'] ?? []);
        
        bool isParticipant = false;
        if (participants.isNotEmpty) {
          isParticipant = participants.contains(userId);
        } else {
          // Fallback: check if the chatId contains the userId as a component
          // Chat IDs are deterministic: userId1_userId2 where IDs are sorted.
          if (chatId.startsWith('${userId}_') || 
              chatId.endsWith('_$userId') || 
              chatId == userId) {
            isParticipant = true;
          }
        }

        if (isParticipant) {
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

  /// Initialize a chat entry when a match occurs.
  Future<void> initializeChat(String userId1, String userId2) async {
    return _mutex.synchronized(() async {
      try {
        final chatId = getChatId(userId1, userId2);
        final legacyChatId = _legacyHashChatId(userId1, userId2);
        final userOrderChatId = '${userId1}_$userId2';
        final reverseUserOrderChatId = '${userId2}_$userId1';
        final chatsJson = await _safeRead('chats_metadata') ?? '{}';
        final Map<String, dynamic> allChats = jsonDecode(chatsJson);

        var metadataChanged = false;
        final participants = [userId1, userId2];

        // Backward-compatible migration: merge legacy keys into the new stable
        // lexicographic key without dropping messages.
        final legacyCandidates = {
          legacyChatId,
          userOrderChatId,
          reverseUserOrderChatId,
        }
          ..remove(chatId);
        for (final candidateChatId in legacyCandidates) {
          if (!allChats.containsKey(candidateChatId)) continue;

          final stableData = allChats[chatId] as Map<String, dynamic>?;
          final legacyData = allChats[candidateChatId] as Map<String, dynamic>?;
          allChats[chatId] = _mergeChatMetadata(
            stableData: stableData,
            legacyData: legacyData,
            participants: participants,
          );
          allChats.remove(candidateChatId);
          metadataChanged = true;

          final stableMessagesRaw = await _safeRead(_messagesKey(chatId));
          final legacyMessagesRaw = await _safeRead(
            _messagesKey(candidateChatId),
          );
          final stableMessages = _decodeJsonStringList(stableMessagesRaw);
          final legacyMessages = _decodeJsonStringList(legacyMessagesRaw);
          final mergedMessages = _mergeMessageJsonLists(
            stableMessages,
            legacyMessages,
          );
          if (mergedMessages.isNotEmpty) {
            await _safeWrite(_messagesKey(chatId), jsonEncode(mergedMessages));
          }
          if (legacyMessagesRaw != null) {
            await _safeDelete(_messagesKey(candidateChatId));
          }
        }

        if (!allChats.containsKey(chatId)) {
          allChats[chatId] = {
            'participants': participants,
            'lastMessage': null,
            'lastMessageTime': null,
            'streak': 0,
            'xp': 0,
          };
          metadataChanged = true;
        } else {
          final existing = Map<String, dynamic>.from(
            allChats[chatId] as Map<String, dynamic>? ?? {},
          );
          final existingParticipants = List<String>.from(
            existing['participants'] ?? const [],
          );
          if (existingParticipants.length < 2 ||
              !existingParticipants.contains(userId1) ||
              !existingParticipants.contains(userId2)) {
            existing['participants'] = participants;
            allChats[chatId] = existing;
            metadataChanged = true;
          }
        }

        if (metadataChanged) {
          await _safeWrite('chats_metadata', jsonEncode(allChats));
        }

        _broadcastChatMetadata(
          chatId,
          allChats[chatId] as Map<String, dynamic>?,
        );
      } catch (e) {
        debugPrint("Error initializing chat: $e");
      }
    });
  }

  /// Send a message to a chat.
  Future<void> sendMessage(String chatId, ChatMessage message) async {
    return _mutex.synchronized(() async {
      try {
        // Save Message
        final messagesKey = _messagesKey(chatId);
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
          // Keep participants only when explicitly available. Avoid parsing
          // chatId with split('_') because user IDs can contain underscores.
          'participants': List<String>.from(chatData['participants'] ?? []),
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
        final messagesKey = _messagesKey(chatId);
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
  Future<Stream<Map<String, dynamic>?>> getChatStream(String chatId) async {
    return _mutex.synchronized(() async {
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

      // Initial value
      final chatsJson = await _safeRead('chats_metadata');
      Map<String, dynamic> allChats = {};
      try {
        if (chatsJson != null) allChats = jsonDecode(chatsJson);
      } catch (e) {
        debugPrint("Error decoding chats_metadata: $e");
      }

      final controller = _chatStreamControllers[chatId]!;
      
      // We return a stream that starts with the current value
      return _createInitialValueStream(
        allChats[chatId] as Map<String, dynamic>?,
        controller.stream,
      );
    });
  }

  /// Get a stream of messages for a chat.
  Future<Stream<List<ChatMessage>>> getMessages(String chatId) async {
    return _mutex.synchronized(() async {
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

      final controller = _messageStreamControllers[chatId]!;
      final history = await getMessageHistory(chatId, limit: 100);

      return _createInitialValueStream(
        history,
        controller.stream,
      );
    });
  }

  /// Helper to prepend an initial value to a stream.
  Stream<T> _createInitialValueStream<T>(T initialValue, Stream<T> source) async* {
    yield initialValue;
    yield* source;
  }

  /// Get recent message history for a chat.
  Future<List<ChatMessage>> getMessageHistory(
    String chatId, {
    int limit = 10,
  }) async {
    try {
      final messagesKey = _messagesKey(chatId);
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
        // Delete metadata
        final chatsJson = await _safeRead('chats_metadata') ?? '{}';
        final Map<String, dynamic> allChats = jsonDecode(chatsJson);

        final keysToDelete = <String>{chatId};
        allChats.forEach((key, rawData) {
          if (rawData is! Map) return;
          final data = Map<String, dynamic>.from(
            rawData.map((k, v) => MapEntry(k.toString(), v)),
          );
          final participants = List<String>.from(data['participants'] ?? const []);
          if (participants.length < 2) return;

          final canonical = getChatId(participants[0], participants[1]);
          if (canonical == chatId) {
            keysToDelete.add(key);
          }
        });

        var metadataChanged = false;
        for (final key in keysToDelete) {
          // Delete messages for every matching key (canonical + legacy aliases).
          await _safeDelete(_messagesKey(key));
          if (allChats.remove(key) != null) {
            metadataChanged = true;
          }
        }

        if (metadataChanged) {
          await _safeWrite('chats_metadata', jsonEncode(allChats));
        }

        // Notify and close stream controllers to prevent memory leaks
        for (final key in keysToDelete) {
          if (_chatStreamControllers.containsKey(key)) {
            _chatStreamControllers[key]!.add(null);
            await _chatStreamControllers[key]!.close();
            _chatStreamControllers.remove(key);
          }

          if (_messageStreamControllers.containsKey(key)) {
            _messageStreamControllers[key]!.add([]);
            await _messageStreamControllers[key]!.close();
            _messageStreamControllers.remove(key);
          }
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
        final messagesKey = _messagesKey(chatId);
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


  void _broadcastChatMetadata(String chatId, Map<String, dynamic>? data) {
    if (_chatStreamControllers.containsKey(chatId)) {
      _chatStreamControllers[chatId]!.add(data);
    }
  }
}
