import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../../data/models.dart';
import '../../firebase_options.dart';
import '../api/socket_api_client.dart';
import '../config/app_config.dart';
import '../socket/socket_client.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await _initializeFirebase();
  }
}

Future<void> _initializeFirebase() {
  if (kIsWeb || AppConfig.hasFirebaseConfig) {
    return Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  return Firebase.initializeApp();
}

class NotificationsController extends ChangeNotifier {
  NotificationsController(this.socket);

  final SocketClient socket;
  late final SocketApiClient api = SocketApiClient(socket);
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final List<AppNotification> notifications = [];
  bool loading = false;
  bool pushReady = false;
  String? fcmToken;
  String? pushError;
  bool _bootstrapped = false;
  bool _pushListenersBound = false;
  String? _pendingUrl;

  Future<void> bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;
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
      if (token != null) {
        unawaited(_subscribeTokenSafely(token));
      } else if (!pushReady) {
        unawaited(configurePush());
      }
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
      pushError = null;
      if (!kIsWeb) {
        await _localNotifications.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('ic_notification'),
            iOS: DarwinInitializationSettings(),
          ),
          onDidReceiveNotificationResponse: (response) {
            _openUrl(response.payload);
          },
        );
        final android =
            _localNotifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await android?.createNotificationChannel(
          const AndroidNotificationChannel(
            'chat_messages',
            'Mensagens',
            description: 'Mensagens privadas e do chat da família.',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
        await android?.requestNotificationsPermission();

        final launchDetails =
            await _localNotifications.getNotificationAppLaunchDetails();
        if (launchDetails?.didNotificationLaunchApp == true) {
          _openUrl(launchDetails?.notificationResponse?.payload);
        }
      }

      if (kIsWeb && !AppConfig.hasFirebaseConfig) return;

      if (Firebase.apps.isEmpty) {
        await _initializeFirebase();
      }
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await FirebaseMessaging.instance.setAutoInitEnabled(true);
      final permission = await FirebaseMessaging.instance
          .requestPermission(alert: true, badge: true, sound: true);
      if (permission.authorizationStatus == AuthorizationStatus.denied) {
        throw StateError('Permissão de notificações negada.');
      }
      fcmToken = await _getTokenWithRetry();
      await _subscribeToken(fcmToken!);

      if (!_pushListenersBound) {
        FirebaseMessaging.instance.onTokenRefresh.listen(_subscribeTokenSafely);
        FirebaseMessaging.onMessage.listen((message) {
          final notification = message.notification;
          if (notification != null && !kIsWeb) {
            final isChat = message.data['type'] == 'chat';
            final conversationId = message.data['conversationId'];
            _localNotifications.show(
              id: message.messageId?.hashCode ?? notification.hashCode,
              title: notification.title,
              body: notification.body,
              payload: message.data['url'],
              notificationDetails: NotificationDetails(
                android: AndroidNotificationDetails(
                  isChat ? 'chat_messages' : 'my_family_notifications',
                  isChat ? 'Mensagens' : 'Nossa Família',
                  icon: 'ic_notification',
                  importance: Importance.max,
                  priority: Priority.max,
                  category: isChat
                      ? AndroidNotificationCategory.message
                      : AndroidNotificationCategory.status,
                  groupKey: isChat && conversationId != null
                      ? 'chat-$conversationId'
                      : null,
                  playSound: true,
                  enableVibration: true,
                ),
                iOS: DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                  threadIdentifier: isChat && conversationId != null
                      ? 'chat-$conversationId'
                      : null,
                ),
              ),
            );
          }
        });
        FirebaseMessaging.onMessageOpenedApp.listen(
          (message) => _openUrl(message.data['url']),
        );
        _pushListenersBound = true;
      }
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) _openUrl(initialMessage.data['url']);
      pushReady = true;
      notifyListeners();
    } catch (error) {
      pushReady = false;
      pushError = _pushErrorMessage(error);
      notifyListeners();
    }
  }

  Future<String> _getTokenWithRetry() async {
    for (var attempt = 0; attempt < 4; attempt++) {
      final token = await FirebaseMessaging.instance.getToken(
        vapidKey: kIsWeb && AppConfig.firebaseWebPushCertificateKey.isNotEmpty
            ? AppConfig.firebaseWebPushCertificateKey
            : null,
      );
      if (token?.isNotEmpty == true) return token!;
      await Future<void>.delayed(Duration(seconds: attempt + 1));
    }
    throw StateError('O Firebase não forneceu um token para este aparelho.');
  }

  Future<void> _subscribeToken(String token) async {
    fcmToken = token;
    await api.mutate<Map<String, dynamic>>('notifications.subscribe', {
      'subscription': {
        'token': token,
        'platform': _platform,
      },
    });
    pushReady = true;
    pushError = null;
    notifyListeners();
  }

  Future<void> _subscribeTokenSafely(String token) async {
    try {
      await _subscribeToken(token);
    } catch (_) {
      fcmToken = token;
      pushReady = false;
      pushError = 'Não foi possível registrar este aparelho no servidor.';
      notifyListeners();
    }
  }

  void _openUrl(Object? rawUrl) {
    final url = rawUrl?.toString();
    if (url == null || !url.startsWith('/')) return;
    final context = navigatorKey.currentContext;
    if (context == null) {
      _pendingUrl = url;
      WidgetsBinding.instance.addPostFrameCallback((_) => openPendingUrl());
      return;
    }
    _pendingUrl = null;
    GoRouter.of(context).go(url);
  }

  void openPendingUrl() {
    final url = _pendingUrl;
    if (url != null) _openUrl(url);
  }

  String get _platform {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'unknown';
  }

  String _pushErrorMessage(Object error) {
    final message = error.toString().replaceFirst('Bad state: ', '');
    return message.isEmpty
        ? 'Não foi possível ativar as notificações.'
        : message;
  }
}
