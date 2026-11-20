import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_commerce_app/core/utils/app_route.dart';
import 'package:e_commerce_app/main.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class InAppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String type; // 'order', 'promo', 'general'
  final String? payload;

  const InAppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.type = 'general',
    this.payload,
  });

  InAppNotification copyWith({bool? isRead}) {
    return InAppNotification(
      id: id,
      title: title,
      body: body,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      type: type,
      payload: payload,
    );
  }
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description:
        'This channel is used for important notifications such as orders, deals, and delivery updates.',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  final ValueNotifier<List<InAppNotification>> notificationsNotifier =
      ValueNotifier<List<InAppNotification>>([]);

  int get unreadCount =>
      notificationsNotifier.value.where((n) => !n.isRead).length;

  bool _initialized = false;
  Map<String, dynamic>? _pendingMessage;
  void flushPending() {
    final data = _pendingMessage;
    _pendingMessage = null;
    if (data != null) _handleMessageData(data);
  }

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        _handleNotificationPayload(response.payload);
      },
    );

    final androidPlugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
      await androidPlugin.requestNotificationsPermission();
    }

    final messaging = FirebaseMessaging.instance;
    await syncDeviceToken();
    messaging.onTokenRefresh.listen((_) => syncDeviceToken());
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    _initialized = true;

    // Foreground FCM listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final title =
          notification?.title ?? message.data['title'] ?? 'New Notification';
      final body = notification?.body ?? message.data['body'] ?? '';
      final payload = jsonEncode(message.data);

      showNotification(
        title: title,
        body: body,
        payload: payload,
        type: message.data['type'] ?? 'general',
      );
    });

    // App opened via notification listener
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageData(message.data);
    });

    // Check for initial message that launched the app
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageData(initialMessage.data);
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    String type = 'general',
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      if (!kIsWeb && _initialized) {
        await _localNotifications.show(
          id,
          title,
          body,
          details,
          payload: payload,
        );
      }
    } catch (e) {
      debugPrint('Error displaying local notification: $e');
    }

    // Add to in-app history
    final newEntry = InAppNotification(
      id: id.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
      payload: payload,
    );
    notificationsNotifier.value = [newEntry, ...notificationsNotifier.value];
  }

  Future<void> showOrderPlacedNotification({
    required String orderId,
    required double totalAmount,
  }) async {
    await showNotification(
      title: 'Order received / تم استلام الطلب',
      body:
          'Your order #$orderId for EGP ${totalAmount.toStringAsFixed(2)} has been received and is awaiting confirmation.',
      type: 'order',
      payload: jsonEncode({'route': AppRoute.profileRoute}),
    );
  }

  Future<void> sendTestNotification() async {
    await showNotification(
      title: 'Live Notification Test 🔔',
      body: 'Notifications are active and working smoothly in Verve Store!',
      type: 'general',
    );
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _history;
  void listenToHistory() {
    _history?.cancel();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      notificationsNotifier.value = [];
      return;
    }
    _history = FirebaseFirestore.instance
        .collection('users/${user.uid}/notifications')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .listen((snapshot) {
          notificationsNotifier.value =
              snapshot.docs.map((doc) {
                final data = doc.data();
                return InAppNotification(
                  id: doc.id,
                  title: data['title'] ?? '',
                  body: data['body'] ?? '',
                  timestamp:
                      DateTime.tryParse(data['createdAt'] ?? '') ??
                      DateTime.now(),
                  isRead: data['isRead'] == true,
                  type: data['type'] ?? 'general',
                  payload: data['payload'],
                );
              }).toList();
        }, onError: (_) {});
  }

  Future<void> clearSession() async {
    await _history?.cancel();
    _history = null;
    notificationsNotifier.value = [];
  }

  Future<void> unlinkDeviceToken() async {
    await clearSession();
    if (kIsWeb) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await FirebaseMessaging.instance.getToken();
      if (user != null && token != null) {
        await FirebaseFirestore.instance
            .doc(
              'users/${user.uid}/devices/${token.hashCode.toUnsigned(32).toRadixString(16)}',
            )
            .delete();
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }

  Future<void> syncDeviceToken() async {
    if (kIsWeb) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      final id = token.hashCode.toUnsigned(32).toRadixString(16);
      await FirebaseFirestore.instance.doc('users/${user.uid}/devices/$id').set(
        {'token': token, 'updatedAt': FieldValue.serverTimestamp()},
      );
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final entries = List<InAppNotification>.from(notificationsNotifier.value);
    notificationsNotifier.value =
        entries.map((item) => item.copyWith(isRead: true)).toList();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final batch = FirebaseFirestore.instance.batch();
      for (final entry in entries) {
        batch.update(
          FirebaseFirestore.instance.doc(
            'users/${user.uid}/notifications/${entry.id}',
          ),
          {'isRead': true},
        );
      }
      await batch.commit();
    } catch (_) {}
  }

  Future<void> clearAll() async {
    final entries = List<InAppNotification>.from(notificationsNotifier.value);
    notificationsNotifier.value = [];
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final batch = FirebaseFirestore.instance.batch();
      for (final entry in entries) {
        batch.delete(
          FirebaseFirestore.instance.doc(
            'users/${user.uid}/notifications/${entry.id}',
          ),
        );
      }
      await batch.commit();
    } catch (_) {}
  }

  void _handleNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload);
      if (data is Map<String, dynamic>) {
        _handleMessageData(data);
      }
    } catch (_) {}
  }

  void _handleMessageData(Map<String, dynamic> data) {
    final navContext = navigtorKey.currentContext;
    if (navContext == null || !navContext.mounted) {
      _pendingMessage = data;
      return;
    }

    final productId = data['product_id'];
    if (productId is String && productId.isNotEmpty) {
      Navigator.of(
        navContext,
      ).pushNamed(AppRoute.productDetailsRoute, arguments: productId);
    } else if (data['route'] == AppRoute.profileRoute) {
      Navigator.of(navContext).pushNamed(AppRoute.profileRoute);
    } else if (data['route'] == AppRoute.cartRoute) {
      Navigator.of(navContext).pushNamed(AppRoute.cartRoute);
    }
  }
}
