import '../../domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  ChatMessageModel({
    required super.id,
    required super.senderId,
    required super.text,
    required super.timestamp,
    super.gameType,
    super.gameData,
    super.stickerUrl,
    super.isRead,
    super.readAt,
  });

  /// Create from a domain [ChatMessage] entity.
  factory ChatMessageModel.fromEntity(ChatMessage message) {
    return ChatMessageModel(
      id: message.id,
      senderId: message.senderId,
      text: message.text,
      timestamp: message.timestamp,
      gameType: message.gameType,
      gameData: message.gameData,
      stickerUrl: message.stickerUrl,
      isRead: message.isRead,
      readAt: message.readAt,
    );
  }

  /// Convert to Map for local storage / Firestore.
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

  /// Create from a Map (local storage / Firestore document).
  factory ChatMessageModel.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessageModel(
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
