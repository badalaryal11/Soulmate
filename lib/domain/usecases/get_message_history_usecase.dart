import '../repositories/chat_repository.dart';
import '../entities/chat_message.dart';

class GetMessageHistoryUseCase {
  final ChatRepository repository;

  GetMessageHistoryUseCase(this.repository);

  Future<List<ChatMessage>> call(String chatId, {int limit = 10}) {
    return repository.getMessageHistory(chatId, limit: limit);
  }
}
