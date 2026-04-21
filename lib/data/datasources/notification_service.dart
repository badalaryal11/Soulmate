import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    final DarwinInitializationSettings initializationSettingsDarwin =
        const DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        debugPrint('Notification clicked: ${response.payload}');
        // Handle navigation here if needed
      },
    );

    // Request permissions for Android 13+ for local notifications.
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'proactive_channel',
      'Proactive Notifications',
      description: 'Notifications to keep you engaged',
      importance: Importance.high,
    );
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    _syncDeviceToken();
    _messaging.onTokenRefresh.listen((token) {
      _upsertTokenForCurrentUser(token);
    });
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) _syncDeviceToken();
    });

    _initialized = true;
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (!await _isPushTypeEnabled(message.data)) {
      return;
    }
    final notification = message.notification;
    final title = notification?.title ?? 'Soulmate';
    final body = notification?.body ?? 'You have a new notification.';

    await _notificationsPlugin.show(
      id: notification.hashCode,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'proactive_channel',
          'Proactive Notifications',
          channelDescription: 'Notifications to keep you engaged',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data.isEmpty ? null : message.data.toString(),
    );
  }

  Future<bool> _isPushTypeEnabled(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final type = (data['type'] ?? '').toString().toLowerCase();
    if (type == 'match') {
      return prefs.getBool('notifications_matches') ?? true;
    }
    if (type == 'message') {
      return prefs.getBool('notifications_messages') ?? true;
    }
    if (type == 'engagement') {
      return prefs.getBool('notifications_engagement') ?? true;
    }
    return true;
  }

  Future<void> _syncDeviceToken() async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    await _upsertTokenForCurrentUser(token);
  }

  Future<void> _upsertTokenForCurrentUser(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'pushTokens': FieldValue.arrayUnion([token]),
        'pushTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to save push token: $e');
    }
  }

  Future<void> syncPushPreferences({
    required bool matchesEnabled,
    required bool messagesEnabled,
    required bool engagementEnabled,
  }) async {
    await _syncTopic('matches', matchesEnabled);
    await _syncTopic('messages', messagesEnabled);
    await _syncTopic('engagement', engagementEnabled);
  }

  Future<void> _syncTopic(String topic, bool enabled) async {
    try {
      if (enabled) {
        await _messaging.subscribeToTopic(topic);
      } else {
        await _messaging.unsubscribeFromTopic(topic);
      }
    } catch (e) {
      debugPrint('Failed to sync topic $topic: $e');
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required Duration delay,
    String? payload,
  }) async {
    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.now(tz.local).add(delay),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'proactive_channel',
            'Proactive Notifications',
            channelDescription: 'Notifications to keep you engaged',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexact,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> sendMessagePush({
    required String recipientUserId,
    required String senderName,
    required String messagePreview,
    required String chatId,
    String? idempotencyKey,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendMessagePush');
      await callable.call({
        'recipientUserId': recipientUserId,
        'senderName': senderName,
        'messagePreview': messagePreview,
        'chatId': chatId,
        if (idempotencyKey != null && idempotencyKey.isNotEmpty)
          'idempotencyKey': idempotencyKey,
      });
    } catch (e) {
      debugPrint('Failed to call sendMessagePush: $e');
    }
  }

  Future<void> sendMatchPush({
    required String recipientUserId,
    required String matcherName,
    String? idempotencyKey,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendMatchPush');
      await callable.call({
        'recipientUserId': recipientUserId,
        'matcherName': matcherName,
        if (idempotencyKey != null && idempotencyKey.isNotEmpty)
          'idempotencyKey': idempotencyKey,
      });
    } catch (e) {
      debugPrint('Failed to call sendMatchPush: $e');
    }
  }
}
