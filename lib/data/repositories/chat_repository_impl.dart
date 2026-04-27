import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/database_service.dart';
import '../../core/error/failures.dart';

class ChatRepositoryImpl implements ChatRepository {
  final DatabaseService _databaseService;

  ChatRepositoryImpl(this._databaseService);

  @override
  Future<List<Map<String, dynamic>>> getActiveChats(String userId) async {
    try {
      return await _databaseService.getActiveChats(userId);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> initializeChat(String userId1, String userId2) async {
    try {
      await _databaseService.initializeChat(userId1, userId2);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<List<ChatMessage>> getMessageHistory(
    String chatId, {
    int limit = 10,
  }) async {
    try {
      return await _databaseService.getMessageHistory(chatId, limit: limit);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<Stream<List<ChatMessage>>> getChatStream(String chatId) async {
    // Streams handle errors differently (via handleError), but usually
    // it's passed through here unless we want to transform the stream.
    final stream = await _databaseService.getMessages(chatId);
    return stream.handleError((e) {
      throw ServerFailure(e.toString());
    });
  }

  @override
  Future<Stream<Map<String, dynamic>?>> getChatMetadataStream(String chatId) async {
    final stream = await _databaseService.getChatStream(chatId);
    return stream.handleError((e) {
      throw ServerFailure(e.toString());
    });
  }

  @override
  Future<void> sendMessage(String chatId, ChatMessage message) async {
    try {
      await _databaseService.sendMessage(chatId, message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updateGameMessage(
    String chatId,
    String messageId,
    Map<String, dynamic> gameData,
  ) async {
    try {
      await _databaseService.updateGameMessage(chatId, messageId, gameData);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<String> getChatId(String userId1, String userId2) async {
    try {
      return _databaseService.getChatId(userId1, userId2);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> deleteChat(String chatId) async {
    try {
      await _databaseService.deleteChat(chatId);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> markMessagesAsRead(String chatId, String currentUserId) async {
    try {
      await _databaseService.markMessagesAsRead(chatId, currentUserId);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
