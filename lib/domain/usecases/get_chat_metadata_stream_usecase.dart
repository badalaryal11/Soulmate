import '../repositories/chat_repository.dart';

class GetChatMetadataStreamUseCase {
  final ChatRepository repository;

  GetChatMetadataStreamUseCase(this.repository);

  Future<Stream<Map<String, dynamic>?>> call(String chatId) {
    return repository.getChatMetadataStream(chatId);
  }
}
