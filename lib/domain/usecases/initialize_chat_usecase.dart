import '../repositories/chat_repository.dart';

class InitializeChatUseCase {
  final ChatRepository repository;

  InitializeChatUseCase(this.repository);

  Future<void> call(String userId1, String userId2) {
    return repository.initializeChat(userId1, userId2);
  }
}
