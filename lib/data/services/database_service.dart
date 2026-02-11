import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soulmate/data/models/user_model.dart';
import '../models/chat_message.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  final FirebaseFirestore _firestore;
  final String _usersCollection = 'users';

  DatabaseService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

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

  Future<void> sendMessage(String chatId, ChatMessage message) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toMap());

      // Update last message time in chat metadata AND increment XP
      await _firestore.collection('chats').doc(chatId).set({
        'lastMessage': message.text,
        'lastMessageTime': message.timestamp.millisecondsSinceEpoch,
        'participants': chatId.split('_'),
        'xp': FieldValue.increment(1), // Increment XP
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error sending message: $e");
      rethrow;
    }
  }

  Stream<DocumentSnapshot> getChatStream(String chatId) {
    return _firestore.collection('chats').doc(chatId).snapshots();
  }

  Stream<List<ChatMessage>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ChatMessage.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  // Get recent messages for AI context
  Future<List<ChatMessage>> getMessageHistory(
    String chatId, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return ChatMessage.fromMap(doc.id, doc.data());
      }).toList();
    } catch (e) {
      debugPrint("Error fetching message history: $e");
      return [];
    }
  }

  // Delete Chat
  Future<void> deleteChat(String chatId) async {
    try {
      // 1. Delete all messages in the subcollection
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      for (var doc in messages.docs) {
        await doc.reference.delete();
      }

      // 2. Delete the chat document itself
      await _firestore.collection('chats').doc(chatId).delete();
    } catch (e) {
      debugPrint("Error deleting chat: $e");
      rethrow;
    }
  }
}
