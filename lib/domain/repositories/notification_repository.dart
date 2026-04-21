/// Abstract interface for notification operations.
///
/// Wraps the concrete [NotificationService] so the presentation
/// layer never imports data-layer classes directly.
abstract class NotificationRepository {
  /// Initialize the notification plugin and request permissions.
  Future<void> initialize();

  /// Applies push settings to topic subscriptions.
  Future<void> syncPushPreferences({
    required bool matchesEnabled,
    required bool messagesEnabled,
    required bool engagementEnabled,
  });

  /// Schedule a notification after [delay].
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required Duration delay,
    String? payload,
  });

  /// Cancel a specific notification by [id].
  Future<void> cancelNotification(int id);

  /// Cancel all pending notifications.
  Future<void> cancelAll();

  /// Send a remote push for a new chat message.
  Future<void> sendMessagePush({
    required String recipientUserId,
    required String senderName,
    required String messagePreview,
    required String chatId,
    String? idempotencyKey,
  });

  /// Send a remote push for a new match.
  Future<void> sendMatchPush({
    required String recipientUserId,
    required String matcherName,
    String? idempotencyKey,
  });
}
