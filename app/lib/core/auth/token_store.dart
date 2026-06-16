import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:fresh_dio/fresh_dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  static const _accessKey = 'my_family_access_token';
  static const _refreshKey = 'my_family_refresh_token';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<String?> readAccessToken() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_accessKey);
      }
      return await _secureStorage.read(key: _accessKey);
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<String?> readRefreshToken() async {
    try {
      if (kIsWeb) {
        return (await SharedPreferences.getInstance()).getString(_refreshKey);
      }
      return _secureStorage.read(key: _refreshKey);
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> writeTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessKey, accessToken);
      if (refreshToken != null) {
        await prefs.setString(_refreshKey, refreshToken);
      }
      return;
    }
    await _secureStorage.write(key: _accessKey, value: accessToken);
    if (refreshToken != null) {
      await _secureStorage.write(key: _refreshKey, value: refreshToken);
    }
  }

  Future<void> clear() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessKey);
      await prefs.remove(_refreshKey);
      return;
    }
    await _secureStorage.delete(key: _accessKey);
    await _secureStorage.delete(key: _refreshKey);
  }
}

class SecureOAuth2TokenStorage implements TokenStorage<OAuth2Token> {
  SecureOAuth2TokenStorage(this.store);

  final TokenStore store;

  @override
  Future<void> delete() => store.clear();

  @override
  Future<OAuth2Token?> read() async {
    final accessToken = await store.readAccessToken();
    if (accessToken == null) return null;
    final refreshToken = await store.readRefreshToken();
    return oauthTokenFromJwt(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  @override
  Future<void> write(OAuth2Token token) {
    return store.writeTokens(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
    );
  }
}

OAuth2Token oauthTokenFromJwt({
  required String accessToken,
  String? refreshToken,
}) {
  final expiresAt = jwtExpiresAt(accessToken);
  final now = DateTime.now().toUtc();
  final expiresIn =
      expiresAt?.difference(now).inSeconds.clamp(0, 2147483647).toInt();
  return OAuth2Token(
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresIn: expiresIn,
    issuedAt: now,
  );
}

DateTime? jwtExpiresAt(String token) {
  try {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    final payload =
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final map = const JsonDecoder().convert(payload) as Map<String, dynamic>;
    final exp = map['exp'];
    if (exp is! num) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      exp.toInt() * 1000,
      isUtc: true,
    );
  } catch (_) {
    return null;
  }
}
