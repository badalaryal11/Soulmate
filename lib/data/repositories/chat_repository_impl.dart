import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/database_service.dart';

class ChatRepositoryImpl implements ChatRepository {
  final DatabaseService _databaseService;

  ChatRepositoryImpl(this._databaseService);

  @override
  Future<List<Map<String, dynamic>>> getActiveChats(String userId) {
    return _databaseService.getActiveChats(userId);
  }

  @override
  Future<List<ChatMessage>> getMessageHistory(String chatId, {int limit = 10}) {
    return _databaseService.getMessageHistory(chatId, limit: limit);
  }

  @override
  Stream<List<ChatMessage>> getChatStream(String chatId) {
    return _databaseService.getMessages(chatId);
  }

  @override
  Future<void> sendMessage(String chatId, ChatMessage message) {
    return _databaseService.sendMessage(chatId, message);
  }

  @override
  Future<void> updateGameMessage(
    String chatId,
    String messageId,
    Map<String, dynamic> gameData,
  ) {
    return _databaseService.updateGameMessage(chatId, messageId, gameData);
  }

  @override
  Future<String> getChatId(String userId1, String userId2) async {
    return _databaseService.getChatId(userId1, userId2);
  }

  @override
  Future<void> deleteChat(String chatId) {
    return _databaseService.deleteChat(chatId);
  }

  @override
  Future<void> markMessagesAsRead(String chatId, String currentUserId) {
    return _databaseService.markMessagesAsRead(chatId, currentUserId);
  }
}
