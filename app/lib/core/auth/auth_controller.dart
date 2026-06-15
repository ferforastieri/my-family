import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../data/models.dart';
import '../api/socket_api_client.dart';
import '../config/app_config.dart';
import '../socket/socket_client.dart';
import 'token_store.dart';

class AuthController extends ChangeNotifier {
  AuthController(this.socket, this.tokenStore);

  final SocketClient socket;
  final TokenStore tokenStore;
  late final SocketApiClient api = SocketApiClient(socket);

  AppUser? user;
  bool loading = true;
  String? token;
  String? refreshToken;
  bool _connectListenerBound = false;
  Completer<bool>? _refreshCompleter;
  String? takeMessage() => socket.takeLastMessage();

  Future<void> bootstrap() async {
    token = await tokenStore.readAccessToken();
    refreshToken = await tokenStore.readRefreshToken();
    socket.onAuthError = _refreshSession;
    _bindConnectListener();
    socket.connect(token: token);
    if (token != null || refreshToken != null) {
      try {
        await _restoreSession().timeout(const Duration(seconds: 18));
      } catch (_) {
        await _clearAuth(notify: false);
      }
    }
    loading = false;
    notifyListeners();
  }

  Future<void> _restoreSession() async {
    if (refreshToken != null) {
      await _refreshSession();
      return;
    }
    if (token != null && await _refreshSession()) {
      return;
    }
    if (token != null) {
      await _loadCurrentUser(clearInvalidToken: true);
      return;
    }
  }

  void _bindConnectListener() {
    if (_connectListenerBound) return;
    socket.on('connect', (_) {
      if (!loading && token != null && user == null) {
        unawaited(_loadCurrentUser(clearInvalidToken: true));
      }
    });
    _connectListenerBound = true;
  }

  Future<void> _loadCurrentUser({required bool clearInvalidToken}) async {
    try {
      final response = await api.query<Map<String, dynamic>>('auth.me');
      user =
          AppUser.fromJson(Map<String, dynamic>.from(response['user'] as Map));
      notifyListeners();
    } catch (error) {
      if (clearInvalidToken && _looksLikeAuthError(error)) {
        if (await _refreshSession()) {
          await _loadCurrentUser(clearInvalidToken: false);
          return;
        }
        await _clearAuth();
        return;
      }
      if (clearInvalidToken) await _clearAuth();
    }
  }

  Future<void> signIn(String email, String password) async {
    final response = await api.mutate<Map<String, dynamic>>('auth.login', {
      'email': email,
      'password': password,
    });
    await _acceptAuth(response);
  }

  Future<void> register(String email, String password, String name) async {
    final response = await api.mutate<Map<String, dynamic>>('auth.register', {
      'email': email,
      'password': password,
      'name': name,
    });
    await _acceptAuth(response);
  }

  Future<void> forgotPassword(String email) {
    return api
        .mutate<Map<String, dynamic>>('auth.forgotPassword', {'email': email});
  }

  Future<void> resetPassword(String token, String newPassword) {
    return api.mutate<Map<String, dynamic>>('auth.resetPassword', {
      'token': token,
      'newPassword': newPassword,
    });
  }

  Future<void> updateMe({required String name}) async {
    final response = await api.mutate<Map<String, dynamic>>('auth.updateMe', {
      'name': name,
    });
    final rawUser = response['user'];
    if (rawUser is Map) {
      user = AppUser.fromJson(Map<String, dynamic>.from(rawUser));
      notifyListeners();
    }
  }

  Future<void> refreshMe() async {
    if (token == null) return;
    try {
      final response = await api.query<Map<String, dynamic>>('auth.me');
      final rawUser = response['user'];
      if (rawUser is Map) {
        user = AppUser.fromJson(Map<String, dynamic>.from(rawUser));
        notifyListeners();
      }
    } catch (error) {
      if (_looksLikeAuthError(error) && await _refreshSession()) {
        await refreshMe();
        return;
      }
      rethrow;
    }
  }

  Future<void> updateAvatar(XFile file) async {
    final bytes = await file.readAsBytes();
    Future<http.Response> send(String? authToken) async {
      final request = http.MultipartRequest(
        'POST',
        AppConfig.apiUri('/auth/avatar'),
      );
      if (authToken != null) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name,
      ));
      final streamed = await request.send();
      return http.Response.fromStream(streamed);
    }

    var response = await send(token);
    if (response.statusCode == 401 && await _refreshSession()) {
      response = await send(token);
    }
    final body = response.body;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(body.isEmpty ? 'Erro ao enviar avatar.' : body);
    }

    final raw = await compute(_decodeJsonMap, body);
    final message = raw['message'];
    if (message is String) socket.rememberMessage(message);
    final data = raw['data'] is Map
        ? Map<String, dynamic>.from(raw['data'] as Map)
        : raw;
    final rawUser = data['user'];
    if (rawUser is Map) {
      user = AppUser.fromJson(Map<String, dynamic>.from(rawUser));
      notifyListeners();
    }
  }

  Future<bool> _refreshSession() async {
    final activeRefresh = _refreshCompleter;
    if (activeRefresh != null) return activeRefresh.future;
    final credential = refreshToken ?? token;
    if (credential == null) return false;
    final completer = Completer<bool>();
    _refreshCompleter = completer;
    try {
      final response = await api.mutate<Map<String, dynamic>>('auth.refresh', {
        'refreshToken': credential,
      });
      await _acceptAuth(response);
      completer.complete(true);
      return true;
    } catch (_) {
      await _clearAuth();
      completer.complete(false);
      return false;
    } finally {
      if (identical(_refreshCompleter, completer)) _refreshCompleter = null;
    }
  }

  Future<void> _clearAuth({bool notify = true}) async {
    user = null;
    token = null;
    refreshToken = null;
    await tokenStore.clear();
    socket.connect();
    if (notify) notifyListeners();
  }

  Future<void> signOut() async {
    await _clearAuth();
  }

  Future<void> _acceptAuth(Map<String, dynamic> response) async {
    token = (response['accessToken'] ?? response['access_token']) as String;
    final nextRefreshToken =
        response['refreshToken'] ?? response['refresh_token'];
    if (nextRefreshToken is String && nextRefreshToken.isNotEmpty) {
      refreshToken = nextRefreshToken;
    }
    user = AppUser.fromJson(Map<String, dynamic>.from(response['user'] as Map));
    await tokenStore.writeTokens(
      accessToken: token!,
      refreshToken: refreshToken,
    );
    socket.connect(token: token, force: true);
    notifyListeners();
    unawaited(socket.ensureConnected(token: token).catchError((_) {}));
  }
}

Map<String, dynamic> _decodeJsonMap(String body) {
  return Map<String, dynamic>.from(
      const JsonDecoder().convert(body) as Map<dynamic, dynamic>);
}

bool _looksLikeAuthError(Object error) {
  final message = error.toString().toLowerCase();
  return message.contains('unauthorized') ||
      message.contains('não autorizado') ||
      message.contains('nao autorizado') ||
      message.contains('invalid token') ||
      message.contains('token inválido') ||
      message.contains('token invalido') ||
      message.contains('jwt');
}
