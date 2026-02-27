import '../repositories/chat_repository.dart';

class GetChatIdUseCase {
  final ChatRepository repository;

  GetChatIdUseCase(this.repository);

  Future<String> call(String userId1, String userId2) {
    return repository.getChatId(userId1, userId2);
  }
}
