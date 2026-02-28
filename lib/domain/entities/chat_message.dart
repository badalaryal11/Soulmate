class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final String? gameType;
  final Map<String, dynamic>? gameData;
  final String? stickerUrl;
  final bool isRead;
  final DateTime? readAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.gameType,
    this.gameData,
    this.stickerUrl,
    this.isRead = false,
    this.readAt,
  });

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? text,
    DateTime? timestamp,
    String? gameType,
    Map<String, dynamic>? gameData,
    String? stickerUrl,
    bool? isRead,
    DateTime? readAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      gameType: gameType ?? this.gameType,
      gameData: gameData ?? this.gameData,
      stickerUrl: stickerUrl ?? this.stickerUrl,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
    );
  }
}
