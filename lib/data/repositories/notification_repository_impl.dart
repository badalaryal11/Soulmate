import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_service.dart';

/// Concrete implementation of [NotificationRepository] backed by [NotificationService].
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationService _notificationService;

  NotificationRepositoryImpl(this._notificationService);

  @override
  Future<void> initialize() async {
    await _notificationService.initialize();
  }

  @override
  Future<void> syncPushPreferences({
    required bool matchesEnabled,
    required bool messagesEnabled,
    required bool engagementEnabled,
  }) async {
    await _notificationService.syncPushPreferences(
      matchesEnabled: matchesEnabled,
      messagesEnabled: messagesEnabled,
      engagementEnabled: engagementEnabled,
    );
  }

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required Duration delay,
    String? payload,
  }) async {
    await _notificationService.scheduleNotification(
      id: id,
      title: title,
      body: body,
      delay: delay,
      payload: payload,
    );
  }

  @override
  Future<void> cancelNotification(int id) async {
    await _notificationService.cancelNotification(id);
  }

  @override
  Future<void> cancelAll() async {
    await _notificationService.cancelAll();
  }

  @override
  Future<void> sendMessagePush({
    required String recipientUserId,
    required String senderName,
    required String messagePreview,
    required String chatId,
    String? idempotencyKey,
  }) async {
    await _notificationService.sendMessagePush(
      recipientUserId: recipientUserId,
      senderName: senderName,
      messagePreview: messagePreview,
      chatId: chatId,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<void> sendMatchPush({
    required String recipientUserId,
    required String matcherName,
    String? idempotencyKey,
  }) async {
    await _notificationService.sendMatchPush(
      recipientUserId: recipientUserId,
      matcherName: matcherName,
      idempotencyKey: idempotencyKey,
    );
  }
}
