import '../repositories/chat_repository.dart';

class MarkMessagesAsReadUseCase {
  final ChatRepository repository;

  MarkMessagesAsReadUseCase(this.repository);

  Future<void> call(String chatId, String currentUserId) {
    return repository.markMessagesAsRead(chatId, currentUserId);
  }
}
