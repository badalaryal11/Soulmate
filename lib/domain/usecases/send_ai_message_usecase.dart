import '../repositories/ai_chat_repository.dart';

class SendAiMessageUseCase {
  final AiChatRepository repository;

  SendAiMessageUseCase(this.repository);

  Future<String> call(List<Map<String, String>> messages) {
    return repository.sendMessage(messages);
  }
}
