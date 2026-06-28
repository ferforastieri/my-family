import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../socket/socket_client.dart';

class HttpApiClient {
  const HttpApiClient(this.socket);

  final SocketClient socket;

  Future<T> query<T>(String event, [Object? payload]) {
    return _request<T>(event, payload, readOnly: true);
  }

  Future<T> mutate<T>(String event, [Object? payload]) {
    return _request<T>(event, payload, readOnly: false);
  }

  Future<T> _request<T>(
    String event,
    Object? payload, {
    required bool readOnly,
  }) async {
    final spec = _route(event, payload, readOnly: readOnly);
    final freshToken = await socket.onBeforeRequest?.call();
    try {
      return await _send<T>(spec, freshToken ?? socket.token);
    } catch (error) {
      if (_looksLikeAuthError(error) &&
          socket.onAuthError != null &&
          await socket.onAuthError!()) {
        final retryToken = await socket.onBeforeRequest?.call();
        return _send<T>(spec, retryToken ?? socket.token);
      }
      rethrow;
    }
  }

  Future<T> _send<T>(_HttpRoute spec, String? token) async {
    final uri = AppConfig.apiUri(
      spec.path,
    ).replace(queryParameters: spec.query.isEmpty ? null : spec.query);
    final headers = <String, String>{
      'Accept': 'application/json',
      if (spec.body != null) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final response = await http.Request(
      spec.method,
      uri,
    ).sendWith(headers: headers, body: spec.body);
    final raw = await response.stream.bytesToString();
    final decoded = raw.trim().isEmpty ? null : jsonDecode(raw);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_message(decoded) ?? raw);
    }
    if (decoded is Map) {
      final message = decoded['message'];
      if (message is String) socket.rememberMessage(message);
      if (decoded.containsKey('data')) return decoded['data'] as T;
    }
    return decoded as T;
  }

  bool _looksLikeAuthError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('401') ||
        message.contains('unauthorized') ||
        message.contains('autenticação') ||
        message.contains('autenticacao') ||
        message.contains('token inválido') ||
        message.contains('token invalido') ||
        message.contains('jwt');
  }

  _HttpRoute _route(String event, Object? payload, {required bool readOnly}) {
    final map = payload is Map ? Map<String, dynamic>.from(payload) : null;
    final query = _query(map);
    switch (event) {
      case 'fotos.list':
        return _HttpRoute.get('/fotos', query);
      case 'fotos.albums':
        return _HttpRoute.get('/fotos/albums');
      case 'fotos.create':
        return _HttpRoute.post('/fotos', payload);
      case 'fotos.update':
        return _HttpRoute.put('/fotos/${map!['id']}', map['data']);
      case 'fotos.delete':
        return _HttpRoute.delete('/fotos/${map!['id']}');
      case 'musicas.list':
        return _HttpRoute.get('/musicas', query);
      case 'musicas.create':
        return _HttpRoute.post('/musicas', payload);
      case 'musicas.update':
        return _HttpRoute.put('/musicas/${map!['id']}', map['data']);
      case 'musicas.delete':
        return _HttpRoute.delete('/musicas/${map!['id']}');
      case 'notas.list':
        return _HttpRoute.get('/notas', query);
      case 'notas.create':
        return _HttpRoute.post('/notas', payload);
      case 'notas.update':
        return _HttpRoute.patch('/notas/${map!['id']}', map['data']);
      case 'notas.delete':
        return _HttpRoute.delete('/notas/${map!['id']}');
      case 'cartas.list':
        return _HttpRoute.get('/cartas', query);
      case 'cartas.create':
        return _HttpRoute.post('/cartas', payload);
      case 'cartas.update':
        return _HttpRoute.put('/cartas/${map!['id']}', map['data']);
      case 'cartas.delete':
        return _HttpRoute.delete('/cartas/${map!['id']}');
      case 'journey.list':
        return _HttpRoute.get('/journey', query);
      case 'journey.create':
        return _HttpRoute.post('/journey', payload);
      case 'journey.update':
        return _HttpRoute.put('/journey/${map!['id']}', map['data']);
      case 'journey.delete':
        return _HttpRoute.delete('/journey/${map!['id']}');
      case 'games.quiz.list':
        return _HttpRoute.get('/games/quiz', query);
      case 'games.quiz.admin.list':
        return _HttpRoute.get('/games/quiz/admin', query);
      case 'games.quiz.create':
        return _HttpRoute.post('/games/quiz', payload);
      case 'games.quiz.update':
        return _HttpRoute.patch('/games/quiz/${map!['id']}', map['data']);
      case 'games.quiz.delete':
        return _HttpRoute.delete('/games/quiz/${map!['id']}');
      case 'games.words.list':
        return _HttpRoute.get('/games/words', query);
      case 'games.words.admin.list':
        return _HttpRoute.get('/games/words/admin', query);
      case 'games.words.create':
        return _HttpRoute.post('/games/words', payload);
      case 'games.words.update':
        return _HttpRoute.patch('/games/words/${map!['id']}', map['data']);
      case 'games.words.delete':
        return _HttpRoute.delete('/games/words/${map!['id']}');
      case 'games.mini.list':
        return _HttpRoute.get('/games/mini', query);
      case 'games.mini.admin.list':
        return _HttpRoute.get('/games/mini/admin', query);
      case 'games.mini.create':
        return _HttpRoute.post('/games/mini', payload);
      case 'games.mini.update':
        return _HttpRoute.patch('/games/mini/${map!['id']}', map['data']);
      case 'games.mini.delete':
        return _HttpRoute.delete('/games/mini/${map!['id']}');
      case 'games.complete':
        return _HttpRoute.post('/games/complete', payload);
      case 'games.stats':
        return _HttpRoute.get('/games/stats', query);
      case 'users.list':
        return _HttpRoute.get('/users', query);
      case 'users.update':
        final body = Map<String, dynamic>.from(map!)..remove('id');
        return _HttpRoute.patch('/users/${map['id']}', body);
      case 'users.delete':
        return _HttpRoute.delete('/users/${map!['id']}');
      case 'notifications.list':
        return _HttpRoute.get('/notifications', query);
      case 'notifications.create':
        return _HttpRoute.post('/notifications', payload);
      case 'notifications.update':
        return _HttpRoute.patch('/notifications/${map!['id']}', map['data']);
      case 'notifications.delete':
        return _HttpRoute.delete('/notifications/${map!['id']}');
      case 'notifications.clear':
        return _HttpRoute.delete('/notifications');
      case 'notifications.send':
        return _HttpRoute.post('/notifications/send', payload);
      case 'notifications.schedule':
        return _HttpRoute.post('/notifications/schedule', payload);
      case 'notifications.scheduled.list':
        return _HttpRoute.get('/notifications/scheduled/list', query);
      case 'notifications.scheduled.delete':
        return _HttpRoute.delete('/notifications/scheduled/${map!['id']}');
      case 'notifications.read':
        return _HttpRoute.patch('/notifications/${map!['id']}/read');
      case 'notifications.readAll':
        return _HttpRoute.patch('/notifications/read-all');
      case 'notifications.subscribe':
        return _HttpRoute.post('/notifications/subscribe', payload);
      case 'notifications.unsubscribe':
        return _HttpRoute.post('/notifications/unsubscribe', payload);
      case 'lists.list':
        return _HttpRoute.get('/lists', query);
      case 'lists.create':
        return _HttpRoute.post('/lists', payload);
      case 'lists.update':
        return _HttpRoute.patch('/lists/${map!['id']}', map['data']);
      case 'lists.delete':
        return _HttpRoute.delete('/lists/${map!['id']}');
      case 'lists.items':
        return _HttpRoute.get('/lists/${map!['listId']}/items', query);
      case 'lists.items.create':
        return _HttpRoute.post('/lists/${map!['listId']}/items', payload);
      case 'lists.items.update':
        return _HttpRoute.patch('/lists/items/${map!['id']}', map['data']);
      case 'lists.items.delete':
        return _HttpRoute.delete('/lists/items/${map!['id']}');
      case 'location.update':
        return _HttpRoute.post('/location/update', payload);
      case 'location.latest':
        return _HttpRoute.get('/location/latest', query);
      case 'location.places':
        return _HttpRoute.get('/location/places');
      case 'location.places.create':
        return _HttpRoute.post('/location/places', payload);
      case 'location.places.update':
        return _HttpRoute.patch('/location/places/${map!['id']}', map['data']);
      case 'location.places.delete':
        return _HttpRoute.delete('/location/places/${map!['id']}');
      case 'home.settings.get':
        return _HttpRoute.get('/home-settings');
      case 'home.settings.update':
        return _HttpRoute.put('/home-settings', payload);
      case 'chat.users':
        return _HttpRoute.get('/chat/users');
      case 'chat.conversations':
        return _HttpRoute.get('/chat/conversations', query);
      case 'chat.conversation.create':
        return _HttpRoute.post('/chat/conversations', payload);
      case 'chat.messages':
        return _HttpRoute.get(
          '/chat/conversations/${map!['conversationId']}/messages',
          query,
        );
      case 'chat.message.send':
        return _HttpRoute.post(
          '/chat/conversations/${map!['conversationId']}/messages',
          payload,
        );
      case 'chat.messages.read':
        return _HttpRoute.patch(
          '/chat/conversations/${map!['conversationId']}/read',
        );
      case 'chat.message.edit':
        return _HttpRoute.patch('/chat/messages/${map!['messageId']}', {
          'text': map['text'],
        });
      case 'chat.message.delete':
        return _HttpRoute.delete('/chat/messages/${map!['messageId']}');
      case 'chat.typing':
        return _HttpRoute.post('/chat/typing', payload);
      case 'client.dashboard.get':
        return _HttpRoute.get('/client/dashboard');
    }
    throw UnsupportedError('Rota HTTP não mapeada: $event');
  }

  Map<String, String> _query(Map<String, dynamic>? payload) {
    if (payload == null) return const {};
    return payload.map((key, value) => MapEntry(key, value.toString()));
  }

  String? _message(Object? decoded) {
    if (decoded is Map) {
      final message = decoded['message'] ?? decoded['error'];
      if (message is List) return message.join(', ');
      return message?.toString();
    }
    return null;
  }
}

class _HttpRoute {
  const _HttpRoute(this.method, this.path, this.query, this.body);

  factory _HttpRoute.get(String path, [Map<String, String> query = const {}]) =>
      _HttpRoute('GET', path, query, null);
  factory _HttpRoute.post(String path, [Object? body]) =>
      _HttpRoute('POST', path, const {}, body);
  factory _HttpRoute.put(String path, [Object? body]) =>
      _HttpRoute('PUT', path, const {}, body);
  factory _HttpRoute.patch(String path, [Object? body]) =>
      _HttpRoute('PATCH', path, const {}, body);
  factory _HttpRoute.delete(String path) =>
      _HttpRoute('DELETE', path, const {}, null);

  final String method;
  final String path;
  final Map<String, String> query;
  final Object? body;
}

extension on http.Request {
  Future<http.StreamedResponse> sendWith({
    required Map<String, String> headers,
    Object? body,
  }) {
    this.headers.addAll(headers);
    if (body != null) this.body = jsonEncode(body);
    return send();
  }
}
