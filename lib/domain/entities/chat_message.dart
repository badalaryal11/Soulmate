class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final String? gameType;
  final Map<String, dynamic>? gameData;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.gameType,
    this.gameData,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'gameType': gameType,
      'gameData': gameData,
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
    );
  }
}
