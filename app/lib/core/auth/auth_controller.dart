import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fresh_dio/fresh_dio.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../data/models.dart';
import '../config/app_config.dart';
import '../socket/socket_client.dart';
import 'token_store.dart';

class AuthController extends ChangeNotifier {
  AuthController(this.socket, this.tokenStore) {
    _fresh = Fresh.oAuth2<OAuth2Token>(
      tokenStorage: SecureOAuth2TokenStorage(tokenStore),
      httpClient: Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
      )),
      refreshToken: _refreshOAuthToken,
      shouldRefresh: (response) {
        final status = response?.statusCode;
        return status == 401 || status == 403;
      },
      shouldRefreshBeforeRequest: (_, token) {
        final expiresAt = token?.expiresAt;
        if (expiresAt == null) return false;
        return expiresAt.difference(DateTime.now().toUtc()) <
            const Duration(minutes: 2);
      },
      isTokenRequired: (options) {
        final path = options.path;
        return !(path.contains('/auth/login') ||
            path.contains('/auth/register') ||
            path.contains('/auth/refresh') ||
            path.contains('/auth/forgot-password') ||
            path.contains('/auth/reset-password'));
      },
    );
    dio.interceptors.add(_fresh);
  }

  final SocketClient socket;
  final TokenStore tokenStore;
  late final Fresh<OAuth2Token> _fresh;
  late final Dio dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    sendTimeout: const Duration(seconds: 20),
  ));

  AppUser? user;
  TenantInfo? tenant;
  bool loading = true;
  String? token;
  String? refreshToken;
  bool _connectListenerBound = false;
  Completer<bool>? _refreshCompleter;
  String? takeMessage() => socket.takeLastMessage();

  Future<void> bootstrap() async {
    try {
      token = await tokenStore.readAccessToken();
      refreshToken = await tokenStore.readRefreshToken();
      socket.onAuthError = _refreshSession;
      socket.onBeforeRequest = _ensureFreshAccessToken;
      _bindConnectListener();
      socket.connect(token: token);
      if (token != null || refreshToken != null) {
        try {
          await _restoreSession().timeout(const Duration(seconds: 18));
        } catch (_) {
          await _clearAuth(notify: false);
        }
      }
    } catch (_) {
      await _clearAuth(notify: false);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _restoreSession() async {
    if (refreshToken != null) {
      await _refreshSession();
      if (user == null) await _loadCurrentUser(clearInvalidToken: true);
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
      final response = await _httpGetMap('/auth/me');
      user =
          AppUser.fromJson(Map<String, dynamic>.from(response['user'] as Map));
      _acceptTenant(response['tenant']);
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
    final response = await _httpPostMap('/auth/login', {
      'email': email,
      'password': password,
    });
    await _acceptAuth(response);
  }

  Future<void> register(
    String email,
    String password,
    String name,
    String familyName, {
    String? slug,
  }) async {
    final response = await _httpPostMap('/auth/register', {
      'email': email,
      'password': password,
      'name': name,
      'familyName': familyName,
      if (slug?.trim().isNotEmpty == true) 'slug': slug!.trim(),
      'locale': 'pt-BR',
    });
    await _acceptAuth(response);
  }

  Future<void> forgotPassword(String email) {
    return _httpPostMap('/auth/forgot-password', {'email': email});
  }

  Future<void> resetPassword(String token, String newPassword) {
    return _httpPostMap('/auth/reset-password', {
      'token': token,
      'newPassword': newPassword,
    });
  }

  Future<void> updateMe({required String name}) async {
    final response = await _httpPatchMap('/auth/me', {
      'name': name,
    });
    final rawUser = response['user'];
    if (rawUser is Map) {
      user = AppUser.fromJson(Map<String, dynamic>.from(rawUser));
      _acceptTenant(response['tenant']);
      notifyListeners();
    }
  }

  Future<void> refreshMe() async {
    if (token == null) return;
    try {
      final response = await _httpGetMap('/auth/me');
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
    if (refreshToken == null && token == null) return false;
    final completer = Completer<bool>();
    _refreshCompleter = completer;
    try {
      final refreshed = await _fresh.refreshToken();
      _acceptOAuthToken(refreshed);
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

  Future<String?> _ensureFreshAccessToken() async {
    final currentToken = await _fresh.token;
    if (currentToken == null) return null;
    if (!_shouldRefreshSoon(currentToken)) return currentToken.accessToken;
    try {
      final refreshed =
          await _fresh.refreshToken(tokenUsedForRequest: currentToken);
      _acceptOAuthToken(refreshed);
    } catch (_) {
      await _clearAuth();
    }
    return token;
  }

  Future<void> _clearAuth({bool notify = true}) async {
    user = null;
    tenant = null;
    token = null;
    refreshToken = null;
    await _fresh.clearToken();
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
    _acceptTenant(response['tenant']);
    await _fresh.setToken(oauthTokenFromJwt(
      accessToken: token!,
      refreshToken: refreshToken,
    ));
    socket.connect(token: token, force: true);
    notifyListeners();
    unawaited(socket.ensureConnected(token: token).catchError((_) {}));
  }

  Future<OAuth2Token> _refreshOAuthToken(
    OAuth2Token? currentToken,
    Dio client,
  ) async {
    final credential = currentToken?.refreshToken ?? refreshToken;
    if (credential == null || credential.isEmpty) {
      throw RevokeTokenException();
    }
    try {
      final response = await client.postUri<Map<String, dynamic>>(
        AppConfig.apiUri('/auth/refresh'),
        data: {'refreshToken': credential},
      );
      final data = _unwrapHttpResponse(response);
      final nextToken = (data['accessToken'] ?? data['access_token']) as String;
      final nextRefresh = data['refreshToken'] ?? data['refresh_token'];
      final rawUser = data['user'];
      token = nextToken;
      if (nextRefresh is String && nextRefresh.isNotEmpty) {
        refreshToken = nextRefresh;
      }
      if (rawUser is Map) {
        user = AppUser.fromJson(Map<String, dynamic>.from(rawUser));
      }
      _acceptTenant(data['tenant']);
      return oauthTokenFromJwt(
        accessToken: nextToken,
        refreshToken: refreshToken,
      );
    } catch (_) {
      throw RevokeTokenException();
    }
  }

  void _acceptOAuthToken(OAuth2Token token) {
    this.token = token.accessToken;
    refreshToken = token.refreshToken ?? refreshToken;
    socket.connect(token: this.token, force: true);
  }

  Future<String> createCheckout() async {
    final response = await _httpPostMap('/billing/checkout', const {});
    return response['checkoutUrl']?.toString() ?? '';
  }

  Future<String> createBillingPortal() async {
    final response = await _httpPostMap('/billing/portal', const {});
    return response['portalUrl']?.toString() ?? '';
  }

  Future<void> refreshTenant() async {
    final response = await _httpGetMap('/tenants/current');
    tenant = TenantInfo.fromJson(response);
    notifyListeners();
  }

  Future<void> updateTenant({
    required String name,
    required String slug,
    required String locale,
  }) async {
    final response = await _httpPatchMap('/tenants/current', {
      'name': name,
      'slug': slug,
      'defaultLocale': locale,
    });
    tenant = TenantInfo.fromJson(response);
    notifyListeners();
  }

  Future<void> setPublished(bool published) async {
    final response = await _httpPostMap(
      '/tenants/current/publication',
      {'isPublished': published},
    );
    tenant = TenantInfo.fromJson(response);
    notifyListeners();
  }

  void _acceptTenant(Object? rawTenant) {
    if (rawTenant is Map) {
      tenant = TenantInfo.fromJson(Map<String, dynamic>.from(rawTenant));
    }
  }

  Future<Map<String, dynamic>> _httpGetMap(
    String path, {
    String? authToken,
  }) async {
    return _unwrapHttpResponse(await dio.getUri<Map<String, dynamic>>(
      AppConfig.apiUri(path),
      options: _httpOptions(authToken),
    ));
  }

  Future<Map<String, dynamic>> _httpPostMap(
    String path,
    Map<String, dynamic> data, {
    String? authToken,
  }) async {
    return _unwrapHttpResponse(await dio.postUri<Map<String, dynamic>>(
      AppConfig.apiUri(path),
      data: data,
      options: _httpOptions(authToken),
    ));
  }

  Future<Map<String, dynamic>> _httpPatchMap(
    String path,
    Map<String, dynamic> data, {
    String? authToken,
  }) async {
    return _unwrapHttpResponse(await dio.patchUri<Map<String, dynamic>>(
      AppConfig.apiUri(path),
      data: data,
      options: _httpOptions(authToken),
    ));
  }

  Options? _httpOptions(String? authToken) {
    if (authToken?.isNotEmpty != true) return null;
    return Options(headers: {'Authorization': 'Bearer $authToken'});
  }

  Map<String, dynamic> _unwrapHttpResponse(Response<dynamic> response) {
    final body = response.data;
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final message = map['message'];
      if (message is String) socket.rememberMessage(message);
      final data = map['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
      return map;
    }
    throw StateError('Resposta inválida do servidor.');
  }
}

bool _shouldRefreshSoon(OAuth2Token token) {
  final expiresAt = token.expiresAt;
  if (expiresAt == null) return false;
  return expiresAt.difference(DateTime.now().toUtc()) <
      const Duration(minutes: 2);
}

Map<String, dynamic> _decodeJsonMap(String body) {
  return Map<String, dynamic>.from(
      const JsonDecoder().convert(body) as Map<dynamic, dynamic>);
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
  if (data is String && data.isNotEmpty) {
    try {
      final decoded = const JsonDecoder().convert(data);
      return _messageFromResponseData(decoded);
    } catch (_) {
      return data;
    }
  }
  return null;
}

bool _looksLikeAuthError(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status == 401 || status == 403) return true;
  }
  final message = error.toString().toLowerCase();
  return message.contains('unauthorized') ||
      message.contains('não autorizado') ||
      message.contains('nao autorizado') ||
      message.contains('invalid token') ||
      message.contains('token inválido') ||
      message.contains('token invalido') ||
      message.contains('jwt');
}
