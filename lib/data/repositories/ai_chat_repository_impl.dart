import '../../domain/repositories/ai_chat_repository.dart';
import '../datasources/chat_service.dart';
import '../../core/error/failures.dart';

/// Concrete implementation of [AiChatRepository] backed by [ChatService].
class AiChatRepositoryImpl implements AiChatRepository {
  final ChatService _chatService;

  AiChatRepositoryImpl(this._chatService);

  @override
  Future<String> sendMessage(List<Map<String, String>> messages) async {
    try {
      return await _chatService.sendMessage(messages);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
