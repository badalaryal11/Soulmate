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

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'gameType': gameType,
      'gameData': gameData,
      'stickerUrl': stickerUrl,
      'isRead': isRead,
      'readAt': readAt?.millisecondsSinceEpoch,
    };
  }

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      gameType: map['gameType'],
      gameData: map['gameData'] != null
          ? Map<String, dynamic>.from(map['gameData'])
          : null,
      stickerUrl: map['stickerUrl'],
      isRead: map['isRead'] ?? false,
      readAt: map['readAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['readAt'])
          : null,
    );
  }
}
