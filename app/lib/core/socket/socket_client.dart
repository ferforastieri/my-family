import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/app_config.dart';

class SocketClient {
  io.Socket? _socket;
  String? _token;
  Completer<void>? _connectCompleter;
  final Map<String, List<void Function(dynamic data)>> _handlers = {};

  bool get isConnected => _socket?.connected ?? false;
  String? get token => _token;

  void connect({String? token}) {
    if (_socket?.connected == true && _token == token) return;
    _token = token;
    _socket?.dispose();
    _connectCompleter = Completer<void>();
    final auth = token == null ? <String, dynamic>{} : {'token': token};
    final headers = token == null
        ? <String, dynamic>{}
        : {'Authorization': 'Bearer $token'};
    _socket = io.io(
      AppConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(kIsWeb ? ['polling', 'websocket'] : ['websocket'])
          .disableAutoConnect()
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
      if (_connectCompleter?.isCompleted == false) {
        _connectCompleter!.complete();
      }
    });
    _socket!.onConnectError((dynamic error) {
      if (_connectCompleter?.isCompleted == false) {
        _connectCompleter!.completeError(
            'Erro ao conectar em ${AppConfig.socketUrl}: ${_socketErrorMessage(error)}');
      }
    });
    _socket!.onError((dynamic error) {
      if (_connectCompleter?.isCompleted == false) {
        _connectCompleter!.completeError(
            'Erro no socket em ${AppConfig.socketUrl}: ${_socketErrorMessage(error)}');
      }
    });
    _socket!.connect();
  }

  Future<void> ensureConnected({String? token}) async {
    connect(token: token ?? _token);
    if (_socket?.connected == true) return;
    await (_connectCompleter?.future ?? Future<void>.value())
        .timeout(const Duration(seconds: 8));
  }

  Future<T> emitAck<T>(String event, [Object? payload]) async {
    await ensureConnected();
    final completer = Completer<T>();
    void exceptionHandler(dynamic error) {
      if (completer.isCompleted) return;
      completer.completeError(_socketErrorMessage(error));
    }

    _socket!.once('exception', exceptionHandler);
    _socket!.emitWithAck(
      event,
      payload,
      ack: (dynamic data) {
        _socket?.off('exception', exceptionHandler);
        if (data is Map && data['status'] == 'error') {
          completer.completeError(data['message'] ?? 'Erro no servidor');
          return;
        }
        completer.complete(data as T);
      },
    );
    return completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw TimeoutException(
          'Tempo esgotado aguardando resposta de "$event". Verifique a conexão com ${AppConfig.socketUrl}.'),
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
}
