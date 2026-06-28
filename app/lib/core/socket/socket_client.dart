import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/app_config.dart';

class SocketClient {
  io.Socket? _socket;
  String? _token;
  Completer<void>? _connectCompleter;
  String? _lastConnectError;
  final Map<String, List<void Function(dynamic data)>> _handlers = {};
  String? _lastMessage;
  Future<bool> Function()? onAuthError;
  Future<String?> Function()? onBeforeRequest;

  bool get isConnected => _socket?.connected ?? false;
  String? get token => _token;
  String? get lastMessage => _lastMessage;

  void rememberMessage(String? message) {
    if (message?.trim().isNotEmpty == true) _lastMessage = message!.trim();
  }

  String? takeLastMessage() {
    final message = _lastMessage;
    _lastMessage = null;
    return message?.isNotEmpty == true ? message : null;
  }

  void connect({String? token, bool force = false}) {
    if (!force && _token == token && _socket != null) {
      if (_socket!.connected) return;
      if (_connectCompleter?.isCompleted == false) return;
    }
    _token = token;
    _socket?.dispose();
    _connectCompleter = Completer<void>();
    _lastConnectError = null;
    final auth = token == null ? <String, dynamic>{} : {'token': token};
    final headers = token == null
        ? <String, String>{}
        : <String, String>{'Authorization': 'Bearer $token'};
    _socket = io.io(
      _normalizeSocketIoUrl(AppConfig.socketUrl),
      io.OptionBuilder()
          .enableForceNew()
          .disableMultiplex()
          .setTransports(kIsWeb ? ['polling', 'websocket'] : ['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(20)
          .setReconnectionDelay(800)
          .setReconnectionDelayMax(4000)
          .setTimeout(5000)
          .setAuth(auth)
          .setExtraHeaders(headers)
          .build(),
    );
    for (final entry in _handlers.entries) {
      for (final handler in entry.value) {
        _socket!.on(entry.key, handler);
      }
    }
    _socket!.onConnect((_) {
      _lastConnectError = null;
      if (_connectCompleter?.isCompleted == false) {
        _connectCompleter!.complete();
      }
    });
    _socket!.onConnectError((dynamic error) {
      _lastConnectError =
          'Erro ao conectar em ${AppConfig.socketUrl}: ${_socketErrorMessage(error)}';
    });
    _socket!.onError((dynamic error) {
      _lastConnectError =
          'Erro no socket em ${AppConfig.socketUrl}: ${_socketErrorMessage(error)}';
    });
    _socket!.connect();
  }

  Future<void> ensureConnected({String? token}) async {
    final targetToken = token ?? _token;
    connect(token: targetToken);
    if (_socket?.connected == true) return;
    await (_connectCompleter?.future ?? Future<void>.value()).timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        throw TimeoutException(
          _lastConnectError ??
              'Tempo esgotado conectando em ${AppConfig.socketUrl}.',
        );
      },
    );
  }

  String _socketErrorMessage(dynamic error) {
    if (error is Map) {
      final message = error['message'] ?? error['error'];
      if (message is List && message.isNotEmpty) return message.join(', ');
      if (message != null) return message.toString();
    }
    return error?.toString() ?? 'Erro no servidor';
  }

  void on(String event, void Function(dynamic data) handler) {
    _handlers.putIfAbsent(event, () => []).add(handler);
    _socket?.on(event, handler);
  }

  void off(String event, [void Function(dynamic data)? handler]) {
    if (handler == null) {
      _handlers.remove(event);
      _socket?.off(event);
      return;
    }
    final handlers = _handlers[event];
    handlers?.remove(handler);
    if (handlers != null && handlers.isEmpty) _handlers.remove(event);
    _socket?.off(event, handler);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  String _normalizeSocketIoUrl(String url) {
    if (url.startsWith('ws://')) return 'http://${url.substring(5)}';
    if (url.startsWith('wss://')) return 'https://${url.substring(6)}';
    return url;
  }
}
