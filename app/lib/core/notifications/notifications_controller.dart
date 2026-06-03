import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../data/models.dart';
import '../../firebase_options.dart';
import '../api/socket_api_client.dart';
import '../config/app_config.dart';
import '../socket/socket_client.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (AppConfig.hasFirebaseConfig && Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  }
}

class NotificationsController extends ChangeNotifier {
  NotificationsController(this.socket);

  final SocketClient socket;
  late final SocketApiClient api = SocketApiClient(socket);
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final List<AppNotification> notifications = [];
  bool loading = false;
  bool pushReady = false;
  String? fcmToken;
  bool _pushListenersBound = false;

  Future<void> bootstrap() async {
    socket.on('notifications.created', (data) {
      if (data is Map) {
        final item = AppNotification.fromJson(Map<String, dynamic>.from(data));
        final index = notifications
            .indexWhere((notification) => notification.id == item.id);
        if (index >= 0) {
          notifications[index] = item;
        } else {
          notifications.insert(0, item);
        }
        notifyListeners();
      }
    });
    socket.on('notifications.updated', (data) {
      if (data is Map) {
        final item = AppNotification.fromJson(Map<String, dynamic>.from(data));
        final index = notifications
            .indexWhere((notification) => notification.id == item.id);
        if (index >= 0) {
          notifications[index] = item;
        } else {
          notifications.insert(0, item);
        }
        notifyListeners();
      }
    });
    socket.on('notifications.deleted', (data) {
      final id = data is Map ? data['id'].toString() : data.toString();
      notifications.removeWhere((notification) => notification.id == id);
      notifyListeners();
    });
    socket.on('notifications.cleared', (_) {
      notifications.clear();
      notifyListeners();
    });
    socket.on('connect', (_) {
      final token = fcmToken;
      if (token != null) unawaited(_subscribeTokenSafely(token));
    });

    await configurePush();
    try {
      await refresh();
    } catch (_) {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    loading = true;
    notifyListeners();
    try {
      final data = await api
          .query<dynamic>('notifications.list', {'page': 1, 'limit': 30});
      final rows = data is List
          ? data
          : ((Map<String, dynamic>.from(data as Map)['items'] as List?) ??
              const []);
      notifications
        ..clear()
        ..addAll(rows.map((row) =>
            AppNotification.fromJson(Map<String, dynamic>.from(row as Map))));
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> configurePush() async {
    try {
      if (!kIsWeb) {
        await _localNotifications.initialize(
          settings: const InitializationSettings(
              android: AndroidInitializationSettings('ic_notification')),
        );
        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }

      if (!AppConfig.hasFirebaseConfig) return;

      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform);
      }
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await FirebaseMessaging.instance
          .requestPermission(alert: true, badge: true, sound: true);
      fcmToken = await FirebaseMessaging.instance.getToken(
        vapidKey: kIsWeb && AppConfig.firebaseWebPushCertificateKey.isNotEmpty
            ? AppConfig.firebaseWebPushCertificateKey
            : null,
      );
      if (fcmToken != null) unawaited(_subscribeTokenSafely(fcmToken!));

      if (!_pushListenersBound) {
        FirebaseMessaging.instance.onTokenRefresh.listen(_subscribeTokenSafely);
        FirebaseMessaging.onMessage.listen((message) {
          final notification = message.notification;
          if (notification != null && !kIsWeb) {
            _localNotifications.show(
              id: notification.hashCode,
              title: notification.title,
              body: notification.body,
              notificationDetails: const NotificationDetails(
                android: AndroidNotificationDetails(
                  'my_family_notifications',
                  'Nossa Família',
                  icon: 'ic_notification',
                  importance: Importance.high,
                  priority: Priority.high,
                ),
              ),
            );
          }
        });
        _pushListenersBound = true;
      }
      pushReady = true;
      notifyListeners();
    } catch (_) {
      pushReady = false;
      notifyListeners();
    }
  }

  Future<void> _subscribeToken(String token) async {
    fcmToken = token;
    await api.mutate<Map<String, dynamic>>('notifications.subscribe', {
      'subscription': {
        'token': token,
        'platform': _platform,
      },
    });
  }

  Future<void> _subscribeTokenSafely(String token) async {
    try {
      await _subscribeToken(token);
    } catch (_) {
      fcmToken = token;
    }
  }

  String get _platform {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'unknown';
  }
}
