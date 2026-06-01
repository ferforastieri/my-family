import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/app_config.dart';

class SocketClient {
  io.Socket? _socket;
  String? _token;

  bool get isConnected => _socket?.connected ?? false;

  void connect({String? token}) {
    if (_socket?.connected == true && _token == token) return;
    _token = token;
    _socket?.dispose();
    _socket = io.io(
      AppConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth(token == null ? <String, dynamic>{} : {'token': token})
          .build(),
    );
    _socket!.connect();
  }

  Future<T> emitAck<T>(String event, [Object? payload]) {
    connect(token: _token);
    final completer = Completer<T>();
    _socket!.emitWithAck(
      event,
      payload,
      ack: (dynamic data) {
        if (data is Map && data['status'] == 'error') {
          completer.completeError(data['message'] ?? 'Erro no servidor');
          return;
        }
        completer.complete(data as T);
      },
    );
    return completer.future.timeout(const Duration(seconds: 20));
  }

  void on(String event, void Function(dynamic data) handler) {
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
