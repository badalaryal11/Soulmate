import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

import '../../domain/entities/user.dart' as domain;
import '../../domain/entities/chat_message.dart';
import 'user_database_service.dart';
import 'chat_database_service.dart';
import 'feedback_service.dart';

/// Facade that delegates to focused sub-services.
///
/// Maintains backward compatibility for existing callers while the codebase
/// is progressively migrated to use the sub-services directly.
class DatabaseService {
  late final UserDatabaseService _userService;
  late final ChatDatabaseService _chatService;
  late final FeedbackService _feedbackService;

  /// Expose sub-services for direct use (preferred in new code).
  UserDatabaseService get userService => _userService;
  ChatDatabaseService get chatService => _chatService;
  FeedbackService get feedbackService => _feedbackService;

  static FirebaseFirestore? _mockFirestoreStatic;
  static FirebaseStorage? _mockStorageStatic;

  @visibleForTesting
  static void setMockInstances({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) {
    _mockFirestoreStatic = firestore;
    _mockStorageStatic = storage;
  }

  DatabaseService({FirebaseFirestore? firestore, FirebaseStorage? storage}) {
    final fs = firestore ?? _mockFirestoreStatic;
    final st = storage ?? _mockStorageStatic;

    _userService = UserDatabaseService(firestore: fs, storage: st);
    _chatService = ChatDatabaseService();
    _feedbackService = FeedbackService(firestore: fs);
  }

  // --- User operations (delegate to UserDatabaseService) ---

  Future<String> uploadProfileImage(String userId, File imageFile) =>
      _userService.uploadProfileImage(userId, imageFile);

  Future<void> saveUser(domain.User user) => _userService.saveUser(user);

  Future<void> updateUserField(String uid, Map<String, dynamic> data) =>
      _userService.updateUserField(uid, data);

  Future<domain.User?> getUser(String uid) => _userService.getUser(uid);

  Future<List<domain.User>> getUsers({
    String? gender,
    String? currentUserId,
    int limit = 10,
    bool refresh = false,
  }) => _userService.getUsers(
    gender: gender,
    currentUserId: currentUserId,
    limit: limit,
    refresh: refresh,
  );

  // --- Chat operations (delegate to ChatDatabaseService) ---

  String getChatId(String userId1, String userId2) =>
      _chatService.getChatId(userId1, userId2);

  Future<List<Map<String, dynamic>>> getActiveChats(String userId) =>
      _chatService.getActiveChats(userId);

  Future<void> sendMessage(String chatId, ChatMessage message) =>
      _chatService.sendMessage(chatId, message);

  Future<void> updateGameMessage(
    String chatId,
    String messageId,
    Map<String, dynamic> gameData,
  ) => _chatService.updateGameMessage(chatId, messageId, gameData);

  Stream<Map<String, dynamic>?> getChatStream(String chatId) =>
      _chatService.getChatStream(chatId);

  Stream<List<ChatMessage>> getMessages(String chatId) =>
      _chatService.getMessages(chatId);

  Future<List<ChatMessage>> getMessageHistory(
    String chatId, {
    int limit = 10,
  }) => _chatService.getMessageHistory(chatId, limit: limit);

  Future<void> deleteChat(String chatId) => _chatService.deleteChat(chatId);

  Future<void> markMessagesAsRead(String chatId, String currentUserId) =>
      _chatService.markMessagesAsRead(chatId, currentUserId);

  // --- Feedback operations (delegate to FeedbackService) ---

  Future<void> saveFeedback(String userId, String message) =>
      _feedbackService.saveFeedback(userId, message);

  // --- Orchestration ---

  /// Wipe all data (debug/admin only). Orchestrates across sub-services.
  Future<void> wipeAllData() async {
    try {
      await _userService.deleteAllUsers();
      await _chatService.deleteAllChats();
      await _feedbackService.deleteAllFeedback();
      debugPrint("All data wiped successfully.");
    } catch (e) {
      debugPrint("Error wiping data: $e");
      rethrow;
    }
  }
}
