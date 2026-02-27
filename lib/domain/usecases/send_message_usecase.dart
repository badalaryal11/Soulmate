import '../repositories/chat_repository.dart';
import '../entities/chat_message.dart';

class SendMessageUseCase {
  final ChatRepository repository;

  SendMessageUseCase(this.repository);

  Future<void> call(String chatId, ChatMessage message) {
    return repository.sendMessage(chatId, message);
  }
}
