import '../entities/chat_message.dart';

abstract class ChatRepository {
  Future<List<Map<String, dynamic>>> getActiveChats(String userId);
  Future<List<ChatMessage>> getMessageHistory(String chatId, {int limit = 10});
  Stream<List<ChatMessage>> getChatStream(String chatId);
  Future<void> sendMessage(String chatId, ChatMessage message);
  Future<void> updateGameMessage(
    String chatId,
    String messageId,
    Map<String, dynamic> gameData,
  );
  Future<String> getChatId(String userId1, String userId2);
  Future<void> deleteChat(String chatId);
}
