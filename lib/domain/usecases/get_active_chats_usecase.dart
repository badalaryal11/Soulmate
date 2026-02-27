import '../repositories/chat_repository.dart';

class GetActiveChatsUseCase {
  final ChatRepository repository;

  GetActiveChatsUseCase(this.repository);

  Future<List<Map<String, dynamic>>> call(String userId) {
    return repository.getActiveChats(userId);
  }
}
