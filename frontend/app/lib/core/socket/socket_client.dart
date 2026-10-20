import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';

class SocketClient {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Completer<void>? _connectCompleter;
  String? _lastConnectError;
  final Map<String, List<void Function(dynamic data)>> _handlers = {};
  final Map<int, Completer<dynamic>> _pending = {};
  int _sequence = 0;
  bool _manualClose = false;
  int _attempt = 0;
  String? _lastMessage;

  Future<bool> Function()? onAuthError;
  Future<String?> Function()? onTicket;
  Future<String?> Function()? onBeforeRequest;
  String? csrfToken;

  bool get isConnected => _connected;
  bool _connected = false;
  String? get lastMessage => _lastMessage;

  void rememberMessage(String? message) {
    if (message?.trim().isNotEmpty == true) _lastMessage = message!.trim();
  }

  String? takeLastMessage() {
    final message = _lastMessage;
    _lastMessage = null;
    return message?.isNotEmpty == true ? message : null;
  }

  void connect({String? cookieHeader, bool force = false}) {
    if (!force && _connected) return;
    if (!force && _connectCompleter != null && !_connectCompleter!.isCompleted) {
      return;
    }
    _manualClose = false;
    _attempt = 0;
    unawaited(_open(force: force));
  }

  Future<void> ensureConnected({String? cookieHeader}) async {
    if (_connected) return;
    connect(cookieHeader: cookieHeader);
    final completer = _connectCompleter;
    if (completer == null) return;
    await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException(
          _lastConnectError ??
              'Tempo esgotado conectando em ${AppConfig.socketUrl}.',
        );
      },
    );
  }

  Future<void> _open({bool force = false}) async {
    if (_connecting) return;
    _connecting = true;
    _connectCompleter = Completer<void>();
    _lastConnectError = null;
    try {
      final ticket = await onTicket?.call();
      final uri = _socketUri(ticket);
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      await channel.ready.timeout(const Duration(seconds: 10));
      _connected = true;
      _attempt = 0;
      _subscription = channel.stream.listen(
        _onData,
        onError: (Object error) {
          _lastConnectError = error.toString();
          _connected = false;
        },
        onDone: _onDone,
        cancelOnError: false,
      );
      if (_connectCompleter?.isCompleted == false) {
        _connectCompleter!.complete();
      }
      _emitLocal('connect', null);
    } catch (error) {
      _connected = false;
      _lastConnectError = error.toString();
      if (_connectCompleter?.isCompleted == false) {
        _connectCompleter!.completeError(error);
      }
      _connecting = false;
      final recovered = await _tryRefreshAuth();
      if (!recovered && !_manualClose) {
        _scheduleReconnect();
      }
    } finally {
      _connecting = false;
    }
  }

  bool _connecting = false;

  Future<bool> _tryRefreshAuth() async {
    if (onAuthError == null) return false;
    if (!_looksLikeAuthError(_lastConnectError ?? '')) return false;
    try {
      final ok = await onAuthError!();
      if (ok) {
        await _sleep(const Duration(milliseconds: 200));
        await _open(force: true);
        return true;
      }
    } catch (_) {
      // ignore
    }
    return false;
  }

  void _onData(dynamic raw) {
    if (raw is! String) return;
    late Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      payload = Map<String, dynamic>.from(decoded);
    } catch (_) {
      return;
    }
    final id = payload['id'];
    if (id is int && _pending.containsKey(id)) {
      final completer = _pending.remove(id)!;
      if (payload['ok'] == false) {
        completer.completeError(
          payload['message'] ?? 'Erro no servidor',
        );
      } else {
        final data = payload['data'];
        completer.complete(data ?? payload);
      }
      return;
    }
    final event = payload['event'];
    if (event is! String) return;
    final data = payload['data'];
    final handlers = _handlers[event];
    if (handlers == null) return;
    for (final handler in List.of(handlers)) {
      handler(data);
    }
  }

  void _onDone() {
    _connected = false;
    _subscription = null;
    _emitLocal('disconnect', null);
    final error = Exception(
      _lastConnectError ?? 'Conexão encerrada com ${AppConfig.socketUrl}.',
    );
    for (final completer in _pending.values) {
      if (!completer.isCompleted) completer.completeError(error);
    }
    _pending.clear();
    if (!_manualClose) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_manualClose || _attempt >= 20) return;
    _attempt += 1;
    final delay = Duration(milliseconds: (800 * _attempt).clamp(800, 4000));
    Timer(delay, () {
      if (_manualClose || _connected) return;
      unawaited(_open(force: true));
    });
  }

  Future<void> _sleep(Duration duration) {
    return Future<void>.delayed(duration);
  }

  Future<T> emitAck<T>(String event, [Object? payload]) async {
    try {
      return await _emitAckOnce<T>(event, payload);
    } catch (error) {
      if (_looksLikeAuthError(error) &&
          onAuthError != null &&
          await onAuthError!()) {
        return _emitAckOnce<T>(event, payload);
      }
      rethrow;
    }
  }

  Future<T> _emitAckOnce<T>(String event, [Object? payload]) async {
    await onBeforeRequest?.call();
    await ensureConnected();
    final channel = _channel;
    if (channel == null) {
      throw StateError('Conexão não iniciada.');
    }
    final id = ++_sequence;
    final completer = Completer<dynamic>();
    _pending[id] = completer;
    channel.sink.add(
      jsonEncode({
        'id': id,
        'event': event,
        if (payload != null) 'data': payload,
      }),
    );
    final data = await completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        _pending.remove(id);
        throw TimeoutException(
          'Tempo esgotado aguardando resposta de "$event". Verifique a conexão com ${AppConfig.socketUrl}.',
        );
      },
    );
    if (data is Map && data['message'] is String) {
      _lastMessage = data['message'] as String;
    }
    return data as T;
  }

  bool _looksLikeAuthError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('unauthorized') ||
        message.contains('autenticação') ||
        message.contains('autenticacao') ||
        message.contains('não autorizado') ||
        message.contains('nao autorizado') ||
        message.contains('invalid token') ||
        message.contains('token inválido') ||
        message.contains('token invalido') ||
        message.contains('jwt') ||
        message.contains('401');
  }

  void on(String event, void Function(dynamic data) handler) {
    _handlers.putIfAbsent(event, () => []).add(handler);
  }

  void _emitLocal(String event, dynamic data) {
    final handlers = _handlers[event];
    if (handlers == null) return;
    for (final handler in List.of(handlers)) {
      handler(data);
    }
  }

  void off(String event, [void Function(dynamic data)? handler]) {
    if (handler == null) {
      _handlers.remove(event);
      return;
    }
    final handlers = _handlers[event];
    handlers?.remove(handler);
    if (handlers != null && handlers.isEmpty) _handlers.remove(event);
  }

  void disconnect() {
    _manualClose = true;
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('Conexão encerrada.'));
      }
    }
    _pending.clear();
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _connected = false;
    _connectCompleter = null;
  }

  Uri _socketUri(String? ticket) {
    final raw = AppConfig.socketUrl.trim();
    final base = Uri.parse(raw);
    final scheme = base.scheme == 'https'
        ? 'wss'
        : base.scheme == 'http'
            ? 'ws'
            : base.scheme;
    final path = base.path.endsWith('/ws')
        ? base.path
        : '${base.path.replaceFirst(RegExp(r'/$'), '')}/ws';
    return base.replace(
      scheme: scheme,
      path: path,
      queryParameters: ticket == null || ticket.isEmpty ? null : {'ticket': ticket},
    );
  }
}
