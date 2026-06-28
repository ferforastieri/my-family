import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../../data/models.dart';
import '../../firebase_options.dart';
import '../api/socket_api_client.dart';
import '../auth/token_store.dart';
import '../config/app_config.dart';
import '../socket/socket_client.dart';

const _chatNotificationCategory = 'chat_message_actions';
const _replyActionId = 'chat_reply';
const _markReadActionId = 'chat_mark_read';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  DartPluginRegistrant.ensureInitialized();
  await _initializeFirebase();
  if (!kIsWeb && message.data['type'] == 'chat') {
    final plugin = FlutterLocalNotificationsPlugin();
    await _initializeLocalNotifications(plugin);
    await _showPushNotification(plugin, message);
  }
}

Future<FirebaseApp>? _firebaseInitialization;

Future<FirebaseApp> _initializeFirebase() {
  if (Firebase.apps.isNotEmpty) return Future.value(Firebase.app());
  final current = _firebaseInitialization;
  if (current != null) return current;
  if (kIsWeb || AppConfig.hasFirebaseConfig) {
    _firebaseInitialization = Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).catchError((error) {
      if (error is FirebaseException && error.code == 'duplicate-app') {
        return Firebase.app();
      }
      throw error;
    });
    return _firebaseInitialization!;
  }
  _firebaseInitialization = Firebase.initializeApp().catchError((error) {
    if (error is FirebaseException && error.code == 'duplicate-app') {
      return Firebase.app();
    }
    throw error;
  });
  return _firebaseInitialization!;
}

Future<void> _initializeLocalNotifications(
  FlutterLocalNotificationsPlugin plugin, {
  DidReceiveNotificationResponseCallback? onResponse,
}) async {
  await plugin.initialize(
    settings: InitializationSettings(
      android: const AndroidInitializationSettings('ic_notification'),
      iOS: DarwinInitializationSettings(
        notificationCategories: <DarwinNotificationCategory>[
          DarwinNotificationCategory(
            _chatNotificationCategory,
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.text(
                _replyActionId,
                'Responder',
                buttonTitle: 'Enviar',
                placeholder: 'Mensagem',
              ),
              DarwinNotificationAction.plain(
                _markReadActionId,
                'Marcar como lida',
              ),
            ],
          ),
        ],
      ),
    ),
    onDidReceiveNotificationResponse: onResponse,
    onDidReceiveBackgroundNotificationResponse:
        notificationActionBackgroundHandler,
  );
}

@pragma('vm:entry-point')
void notificationActionBackgroundHandler(NotificationResponse response) {
  unawaited(_handleNotificationResponse(response));
}

Future<void> _handleNotificationResponse(NotificationResponse response) async {
  final actionId = response.actionId;
  if (actionId != _replyActionId && actionId != _markReadActionId) return;
  final payload = _decodeNotificationPayload(response.payload);
  final conversationId = payload['conversationId']?.toString();
  if (conversationId == null || conversationId.isEmpty) return;

  final token = await TokenStore().readAccessToken();
  if (token == null || token.isEmpty) return;
  final socket = SocketClient()..connect(token: token);
  final api = SocketApiClient(socket);
  try {
    if (actionId == _replyActionId) {
      final text = response.input?.trim();
      if (text == null || text.isEmpty) return;
      await api.mutate<Map<String, dynamic>>('chat.message.send', {
        'conversationId': conversationId,
        'text': text,
      });
    } else {
      await api.mutate<Map<String, dynamic>>('chat.messages.read', {
        'conversationId': conversationId,
      });
    }
  } finally {
    socket.disconnect();
  }
}

Map<String, dynamic> _decodeNotificationPayload(String? payload) {
  if (payload == null || payload.isEmpty) return const {};
  try {
    final decoded = jsonDecode(payload);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {
    if (payload.startsWith('/')) return {'url': payload};
  }
  return const {};
}

String _notificationPayload(RemoteMessage message) {
  return jsonEncode({
    'url': message.data['url'] ?? '/home',
    if (message.data['conversationId'] != null)
      'conversationId': message.data['conversationId'],
  });
}

Future<void> _showPushNotification(
  FlutterLocalNotificationsPlugin plugin,
  RemoteMessage message,
) async {
  final notification = message.notification;
  final title = notification?.title ?? message.data['title'] ?? 'Nossa Família';
  final body = notification?.body ?? message.data['body'] ?? '';
  final isChat = message.data['type'] == 'chat';
  final conversationId = message.data['conversationId'];

  await plugin.show(
    id: message.messageId?.hashCode ?? Object.hash(title, body, conversationId),
    title: title,
    body: body,
    payload: _notificationPayload(message),
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
        groupKey:
            isChat && conversationId != null ? 'chat-$conversationId' : null,
        playSound: true,
        enableVibration: true,
        actions: isChat
            ? const <AndroidNotificationAction>[
                AndroidNotificationAction(
                  _replyActionId,
                  'Responder',
                  inputs: <AndroidNotificationActionInput>[
                    AndroidNotificationActionInput(label: 'Mensagem'),
                  ],
                  semanticAction: SemanticAction.reply,
                  allowGeneratedReplies: true,
                ),
                AndroidNotificationAction(
                  _markReadActionId,
                  'Marcar como lida',
                  semanticAction: SemanticAction.markAsRead,
                ),
              ]
            : null,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: isChat ? _chatNotificationCategory : null,
        threadIdentifier:
            isChat && conversationId != null ? 'chat-$conversationId' : null,
      ),
    ),
  );
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
  Future<void>? _configurePushFuture;
  String? _pendingUrl;
  bool _pushPermissionRequested = false;

  int get badgeCount =>
      notifications.where((notification) => !notification.read).length;

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

  Future<void> ensureDeviceRegistered() async {
    if (!_bootstrapped) {
      await bootstrap();
      return;
    }
    final token = fcmToken;
    if (token?.isNotEmpty == true) {
      await _subscribeTokenSafely(token!);
      return;
    }
    await configurePush();
  }

  Future<void> requestStartupPermissions() async {
    await configurePush(registerDevice: false);
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

  Future<void> markRead(AppNotification notification) async {
    final index =
        notifications.indexWhere((item) => item.id == notification.id);
    if (index >= 0 && !notifications[index].read) {
      notifications[index] = notifications[index].copyWith(read: true);
      notifyListeners();
    }
    try {
      final row = await api.mutate<Map<String, dynamic>>(
        'notifications.read',
        {'id': notification.id},
      );
      final updated = AppNotification.fromJson(row);
      final updatedIndex =
          notifications.indexWhere((item) => item.id == updated.id);
      if (updatedIndex >= 0) {
        notifications[updatedIndex] = updated;
        notifyListeners();
      }
    } catch (_) {
      //
    }
  }

  Future<void> markAllRead() async {
    if (notifications.every((notification) => notification.read)) return;
    for (var i = 0; i < notifications.length; i++) {
      if (!notifications[i].read) {
        notifications[i] = notifications[i].copyWith(read: true);
      }
    }
    notifyListeners();
    try {
      await api.mutate<Map<String, dynamic>>('notifications.readAll');
    } catch (_) {
      await refresh();
    }
  }

  Future<void> configurePush({bool registerDevice = true}) async {
    final current = _configurePushFuture;
    if (current != null) return current;
    _configurePushFuture = _configurePush(registerDevice: registerDevice);
    try {
      await _configurePushFuture;
    } finally {
      _configurePushFuture = null;
    }
  }

  Future<void> _configurePush({required bool registerDevice}) async {
    try {
      pushError = null;
      if (!kIsWeb) {
        await _initializeLocalNotifications(
          _localNotifications,
          onResponse: (response) {
            if (response.actionId == _replyActionId ||
                response.actionId == _markReadActionId) {
              unawaited(_handleNotificationResponse(response));
              return;
            }
            final payload = _decodeNotificationPayload(response.payload);
            _openUrl(payload['url'] ?? response.payload);
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
        await android?.createNotificationChannel(
          const AndroidNotificationChannel(
            'my_family_notifications',
            'Nossa Família',
            description: 'Notificações criadas no painel e avisos da família.',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
        if (!_pushPermissionRequested) {
          await android?.requestNotificationsPermission();
        }

        final launchDetails =
            await _localNotifications.getNotificationAppLaunchDetails();
        if (launchDetails?.didNotificationLaunchApp == true) {
          final payload = _decodeNotificationPayload(
            launchDetails?.notificationResponse?.payload,
          );
          _openUrl(
              payload['url'] ?? launchDetails?.notificationResponse?.payload);
        }
      }

      if (kIsWeb && !AppConfig.hasFirebaseConfig) return;

      await _initializeFirebase();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await FirebaseMessaging.instance.setAutoInitEnabled(true);
      final permission = _pushPermissionRequested
          ? await FirebaseMessaging.instance.getNotificationSettings()
          : await FirebaseMessaging.instance
              .requestPermission(alert: true, badge: true, sound: true);
      _pushPermissionRequested = true;
      if (permission.authorizationStatus == AuthorizationStatus.denied) {
        throw StateError('Permissão de notificações negada.');
      }
      fcmToken = await _getTokenWithRetry();
      if (registerDevice) {
        await _subscribeToken(fcmToken!);
      } else {
        pushReady = true;
        notifyListeners();
      }

      if (!_pushListenersBound) {
        FirebaseMessaging.instance.onTokenRefresh.listen(_subscribeTokenSafely);
        FirebaseMessaging.onMessage.listen((message) {
          if (!kIsWeb &&
              (message.notification != null ||
                  message.data['title'] != null ||
                  message.data['body'] != null)) {
            unawaited(_showPushNotification(_localNotifications, message));
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
    if (url == null || url.isEmpty) return;
    if (!url.startsWith('/')) return;
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
