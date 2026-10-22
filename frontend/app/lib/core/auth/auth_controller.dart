import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models.dart';
import '../config/app_config.dart';
import '../socket/socket_client.dart';
import 'cookie_transport.dart';
import 'authenticated_media.dart';

class AuthController extends ChangeNotifier {
  AuthController(this.socket);

  final SocketClient socket;
  final Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
    ),
  );
  late final Future<void> _ready = sessionCookies.configure(dio);

  AppUser? user;
  bool loading = true;
  String? csrfToken;
  Completer<bool>? _refreshCompleter;

  String? takeMessage() => socket.takeLastMessage();

  static const _cachedUserKey = 'auth.cachedUser';

  Future<void> restoreCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cachedUserKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        user = AppUser.fromJson(Map<String, dynamic>.from(decoded));
        loading = false;
        notifyListeners();
      }
    } catch (_) {
      await prefs.remove(_cachedUserKey);
    }
  }

  Future<void> bootstrap() async {
    try {
      await _ready;
      await _loadCsrf();
      socket.onAuthError = _refreshSession;
      socket.onBeforeRequest = _ensureSession;
      socket.onTicket = _createWsTicket;
      await _reconnectSocket();
      await _loadCurrentUser(retry: true);
    } catch (_) {
      user = null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> login(
    String email,
    String password, {
    String? tenantSlug,
  }) async {
    final path = Uri.base.pathSegments;
    tenantSlug ??= Uri.base.queryParameters['tenantSlug'] ??
        (path.length >= 2 && path.first == 'f' ? path[1] : null);
    final response = await _post(
        '/auth/login',
        {
          'email': email.trim(),
          'password': password,
          if (tenantSlug != null) 'tenantSlug': tenantSlug,
        },
        retry: false);
    await _acceptSession(response);
  }

  Future<void> register(
    String name,
    String email,
    String password, {
    String? tenantSlug,
    String? invitationToken,
  }) async {
    final path = Uri.base.pathSegments;
    tenantSlug ??= Uri.base.queryParameters['tenantSlug'] ??
        (path.length >= 2 && path.first == 'f' ? path[1] : null);
    invitationToken ??= Uri.base.queryParameters['invitation'];
    final response = await _post(
        '/auth/register',
        {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
          if (tenantSlug != null) 'tenantSlug': tenantSlug,
          if (invitationToken != null) 'invitationToken': invitationToken,
        },
        retry: false);
    await _acceptSession(response);
  }

  Future<void> updateMe({required String name}) async {
    final response = await _patch('/auth/me', {'name': name});
    _setUser(response['user']);
  }

  Future<void> refreshMe() => _loadCurrentUser(retry: true);

  Future<void> updateAvatar(XFile file) async {
    await _ready;
    final response = await _request(
      'POST',
      '/auth/avatar',
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(
          await file.readAsBytes(),
          filename: file.name,
        ),
      }),
    );
    _setUser(response['user']);
  }

  Future<void> signOut() async {
    try {
      await _post('/auth/logout', const {}, retry: false);
    } catch (_) {
      // A sessão local ainda deve ser encerrada quando a rede falhar.
    }
    user = null;
    csrfToken = null;
    await clearAuthenticatedMediaHeaders();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedUserKey);
    socket.disconnect();
    notifyListeners();
  }

  Future<void> _loadCurrentUser({required bool retry}) async {
    try {
      final response = await _get('/auth/me', retry: false);
      _setUser(response['user']);
      await refreshAuthenticatedMediaHeaders();
      await _reconnectSocket(force: true);
    } on DioException catch (error) {
      if (retry &&
          error.response?.statusCode == 401 &&
          await _refreshSession()) {
        return _loadCurrentUser(retry: false);
      }
      if (error.response?.statusCode == 401) {
        user = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_cachedUserKey);
        return;
      }
      rethrow;
    }
  }

  Future<void> _loadCsrf() async {
    final response = await _get('/auth/csrf', retry: false);
    csrfToken = response['csrfToken']?.toString();
    socket.csrfToken = csrfToken;
  }

  Future<bool> _refreshSession() async {
    final active = _refreshCompleter;
    if (active != null) return active.future;
    final completer = Completer<bool>();
    _refreshCompleter = completer;
    try {
      if (csrfToken == null) await _loadCsrf();
      final response = await _post('/auth/refresh', const {}, retry: false);
      await _acceptSession(response);
      completer.complete(true);
      return true;
    } catch (_) {
      user = null;
      completer.complete(false);
      return false;
    } finally {
      if (identical(_refreshCompleter, completer)) _refreshCompleter = null;
    }
  }

  Future<String?> _ensureSession() async {
    if (user == null) return null;
    return null;
  }

  Future<String?> _createWsTicket() async {
    try {
      final response = await _post('/auth/ws-ticket', const {}, retry: false);
      return response['ticket']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _acceptSession(Map<String, dynamic> response) async {
    csrfToken = response['csrfToken']?.toString() ?? csrfToken;
    socket.csrfToken = csrfToken;
    _setUser(response['user']);
    await refreshAuthenticatedMediaHeaders();
    await _reconnectSocket(force: true);
  }

  void _setUser(Object? value) {
    if (value is! Map) return;
    final map = Map<String, dynamic>.from(value);
    user = AppUser.fromJson(map);
    unawaited(_cacheUser(map));
    notifyListeners();
  }

  Future<void> _cacheUser(Map<String, dynamic> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedUserKey, jsonEncode(value));
  }

  Future<void> _reconnectSocket({bool force = false}) async {
    final headers = await sessionCookies.headers(AppConfig.apiUri('/'));
    socket.connect(cookieHeader: headers['Cookie'], force: force);
  }

  Future<Map<String, dynamic>> _get(String path, {bool retry = true}) {
    return _request('GET', path, retry: retry);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Object data, {
    bool retry = true,
  }) {
    return _request('POST', path, data: data, retry: retry);
  }

  Future<Map<String, dynamic>> _patch(String path, Object data) {
    return _request('PATCH', path, data: data);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Object? data,
    bool retry = true,
  }) async {
    await _ready;
    try {
      final response = await dio.requestUri<Map<String, dynamic>>(
        AppConfig.apiUri(path),
        data: data,
        options: Options(
          method: method,
          headers: {
            'Accept': 'application/json',
            if (method != 'GET' && csrfToken != null) 'X-CSRF-Token': csrfToken,
          },
        ),
      );
      return _unwrap(response.data);
    } on DioException catch (error) {
      if (retry &&
          error.response?.statusCode == 401 &&
          await _refreshSession()) {
        return _request(method, path, data: data, retry: false);
      }
      rethrow;
    }
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic>? body) {
    if (body == null) throw StateError('Resposta inválida do servidor.');
    final message = body['message'];
    if (message is String) socket.rememberMessage(message);
    final data = body['data'];
    return data is Map ? Map<String, dynamic>.from(data) : body;
  }
}

String authErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    final message = _messageFromResponseData(data);
    if (message != null && message.isNotEmpty) return message;
    if (error.message?.isNotEmpty == true) return error.message!;
  }
  return error.toString().replaceFirst('Exception: ', '');
}

String? _messageFromResponseData(Object? data) {
  if (data is Map) {
    final message = data['message'];
    if (message is String) return message;
    if (message is List) return message.join(', ');
    final error = data['error'];
    if (error is String) return error;
  }
  return null;
}
