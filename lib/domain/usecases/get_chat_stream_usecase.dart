import '../repositories/chat_repository.dart';
import '../entities/chat_message.dart';

class GetChatStreamUseCase {
  final ChatRepository repository;

  GetChatStreamUseCase(this.repository);

  Future<Stream<List<ChatMessage>>> call(String chatId) {
    return repository.getChatStream(chatId);
  }
}
