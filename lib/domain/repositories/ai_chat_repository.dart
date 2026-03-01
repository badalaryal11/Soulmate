/// Abstract interface for AI chat message sending.
///
/// Wraps the concrete ChatService (multi-provider AI API)
/// so the presentation layer never imports data-layer classes.
abstract class AiChatRepository {
  /// Send a list of chat messages to the AI and return the response text.
  Future<String> sendMessage(List<Map<String, String>> messages);
}
