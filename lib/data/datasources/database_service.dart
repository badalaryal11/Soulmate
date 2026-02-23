import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:soulmate/domain/entities/user_model.dart';
import '../../domain/entities/chat_message.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final String _usersCollection = 'users';

  DatabaseService({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  // Local Streams for chat data
  final Map<String, StreamController<Map<String, dynamic>?>>
  _chatStreamControllers = {};
  final Map<String, StreamController<List<ChatMessage>>>
  _messageStreamControllers = {};

  // Upload Profile Image
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      debugPrint("Starting image upload for user: $userId");
      final ref = _storage.ref().child('user_images').child('$userId.jpg');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'picked-file-path': imageFile.path},
      );

      final uploadTask = ref.putFile(imageFile, metadata);
      final snapshot = await uploadTask;

      debugPrint("Upload finished. State: ${snapshot.state}");
      debugPrint(
        "Bytes transferred: ${snapshot.bytesTransferred} / ${snapshot.totalBytes}",
      );

      if (snapshot.state == TaskState.success) {
        final url = await ref.getDownloadURL();
        debugPrint("Download URL retrieved: $url");
        return url;
      } else {
        throw FirebaseException(
          plugin: 'firebase_storage',
          code: 'upload-failed',
          message: 'Upload task finished with state: ${snapshot.state}',
        );
      }
    } catch (e) {
      debugPrint("Error uploading image (DatabaseService): $e");
      rethrow;
    }
  }

  // Save or Update User
  Future<void> saveUser(User user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.id)
          .set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving user: $e");
      rethrow; // Let the UI handle it or just log it
    }
  }

  // Update specific fields
  Future<void> updateUserField(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update(data);
    } catch (e) {
      debugPrint("Error updating user field: $e");
    }
  }

  // Save Feedback
  Future<void> saveFeedback(String userId, String message) async {
    try {
      await _firestore.collection('feedback').add({
        'userId': userId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error saving feedback: $e");
      rethrow;
    }
  }

  // Get User
  Future<User?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        return User.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint("Error getting user: $e");
      return null;
    }
  }

  // Get Multiple Users (Potential Matches)
  Future<List<User>> getUsers({
    String? gender,
    String? currentUserId,
    int limit = 10,
  }) async {
    try {
      Query query = _firestore.collection(_usersCollection);

      // Basic filtering
      if (gender != null && gender != 'everyone') {
        query = query.where('gender', isEqualTo: gender);
      }

      // Ensure we don't fetch the current user
      if (currentUserId != null) {
        // Firestore doesn't support 'not-equal' efficiently with other filters in all cases,
        // so we might filter client-side or use a composite index.
        // For simplicity and small user base, we'll filter client-side after fetch for now
        // if the list is small, or use 'not-in' if supported and indices exist.
        // Let's rely on client-side filtering for the 'currentUserId' to avoid complex index requirements for now.
      }

      QuerySnapshot snapshot = await query.limit(limit).get();

      return snapshot.docs
          .map((doc) => User.fromMap(doc.data() as Map<String, dynamic>))
          .where((user) => user.id != currentUserId) // Client-side exclusion
          .toList();
    } catch (e) {
      debugPrint("Error getting users: $e");
      return [];
    }
  }

  // Chat methods
  String getChatId(String userId1, String userId2) {
    return userId1.hashCode <= userId2.hashCode
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
  }

  // Get Active Chats for User
  Future<List<Map<String, dynamic>>> getActiveChats(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatsJson = prefs.getString('chats_metadata') ?? '{}';
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

  Future<void> sendMessage(String chatId, ChatMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save Message
      final messagesKey = 'chat_messages_$chatId';
      final messagesJson = prefs.getStringList(messagesKey) ?? [];

      final msgMap = message.toMap();
      msgMap['id'] = message.id; // Include ID in map for local storage
      messagesJson.insert(
        0,
        jsonEncode(msgMap),
      ); // Store newest first to match descending order
      await prefs.setStringList(messagesKey, messagesJson);

      // Update Stream
      _broadcastMessages(chatId);

      // Update Metadata
      final chatsJson = prefs.getString('chats_metadata') ?? '{}';
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
      await prefs.setString('chats_metadata', jsonEncode(allChats));

      // Broadcast Metadata change
      _broadcastChatMetadata(chatId, updatedData);
    } catch (e) {
      debugPrint("Error sending message: $e");
      rethrow;
    }
  }

  void _broadcastMessages(String chatId) async {
    if (_messageStreamControllers.containsKey(chatId)) {
      final history = await getMessageHistory(
        chatId,
        limit: 10000,
      ); // effectively all for the stream
      _messageStreamControllers[chatId]!.add(history);
    }
  }

  void _broadcastChatMetadata(String chatId, Map<String, dynamic>? data) {
    if (_chatStreamControllers.containsKey(chatId)) {
      _chatStreamControllers[chatId]!.add(data);
    }
  }

  Stream<Map<String, dynamic>?> getChatStream(String chatId) {
    if (!_chatStreamControllers.containsKey(chatId)) {
      _chatStreamControllers[chatId] =
          StreamController<Map<String, dynamic>?>.broadcast();
    }

    // Send initial value
    SharedPreferences.getInstance().then((prefs) {
      final chatsJson = prefs.getString('chats_metadata') ?? '{}';
      final Map<String, dynamic> allChats = jsonDecode(chatsJson);
      _chatStreamControllers[chatId]!.add(
        allChats[chatId] as Map<String, dynamic>?,
      );
    });

    return _chatStreamControllers[chatId]!.stream;
  }

  Stream<List<ChatMessage>> getMessages(String chatId) {
    if (!_messageStreamControllers.containsKey(chatId)) {
      _messageStreamControllers[chatId] =
          StreamController<List<ChatMessage>>.broadcast();
    }

    // Broadcast initial history
    _broadcastMessages(chatId);

    return _messageStreamControllers[chatId]!.stream;
  }

  // Get recent messages for AI context
  Future<List<ChatMessage>> getMessageHistory(
    String chatId, {
    int limit = 10,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesKey = 'chat_messages_$chatId';
      final messagesJson = prefs.getStringList(messagesKey) ?? [];

      final takeCount = messagesJson.length < limit
          ? messagesJson.length
          : limit;
      final recent = messagesJson.take(takeCount).map((jsonStr) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final id = map['id'] ?? '';
        return ChatMessage.fromMap(id, map);
      }).toList();

      return recent;
    } catch (e) {
      debugPrint("Error fetching message history: $e");
      return [];
    }
  }

  // Delete Chat
  Future<void> deleteChat(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Delete messages
      await prefs.remove('chat_messages_$chatId');

      // Delete metadata
      final chatsJson = prefs.getString('chats_metadata') ?? '{}';
      final Map<String, dynamic> allChats = jsonDecode(chatsJson);
      if (allChats.containsKey(chatId)) {
        allChats.remove(chatId);
        await prefs.setString('chats_metadata', jsonEncode(allChats));
      }

      _broadcastChatMetadata(chatId, null);
      _broadcastMessages(chatId);
    } catch (e) {
      debugPrint("Error deleting chat: $e");
      rethrow;
    }
  }

  // Wipe All Data (Debug/Admin only)
  Future<void> wipeAllData() async {
    try {
      // 1. Batch delete all Users
      final users = await _firestore.collection(_usersCollection).get();
      WriteBatch batch = _firestore.batch();
      int count = 0;
      for (var doc in users.docs) {
        batch.delete(doc.reference);
        count++;
        if (count >= 500) {
          await batch.commit();
          batch = _firestore.batch();
          count = 0;
        }
      }
      await batch.commit();

      // 2. Delete all Chats and Messages (uses batched deleteChat)
      final prefs = await SharedPreferences.getInstance();
      final chatsJson = prefs.getString('chats_metadata') ?? '{}';
      final Map<String, dynamic> allChats = jsonDecode(chatsJson);

      for (var chatId in allChats.keys) {
        await deleteChat(chatId);
      }

      // 3. Batch delete all Feedback
      final feedback = await _firestore.collection('feedback').get();
      batch = _firestore.batch();
      count = 0;
      for (var doc in feedback.docs) {
        batch.delete(doc.reference);
        count++;
        if (count >= 500) {
          await batch.commit();
          batch = _firestore.batch();
          count = 0;
        }
      }
      await batch.commit();

      debugPrint("All data wiped successfully.");
    } catch (e) {
      debugPrint("Error wiping data: $e");
      rethrow;
    }
  }
}
