/// Abstract interface for notification operations.
///
/// Wraps the concrete [NotificationService] so the presentation
/// layer never imports data-layer classes directly.
abstract class NotificationRepository {
  /// Initialize the notification plugin and request permissions.
  Future<void> initialize();

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
}
