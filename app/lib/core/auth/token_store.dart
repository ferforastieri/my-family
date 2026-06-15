import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  static const _legacyKey = 'my_family_token';
  static const _accessKey = 'my_family_access_token';
  static const _refreshKey = 'my_family_refresh_token';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<String?> read() => readAccessToken();

  Future<String?> readAccessToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessKey) ?? prefs.getString(_legacyKey);
    }
    return await _secureStorage.read(key: _accessKey) ??
        await _secureStorage.read(key: _legacyKey);
  }

  Future<String?> readRefreshToken() async {
    if (kIsWeb) {
      return (await SharedPreferences.getInstance()).getString(_refreshKey);
    }
    return _secureStorage.read(key: _refreshKey);
  }

  Future<void> write(String token) => writeTokens(accessToken: token);

  Future<void> writeTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessKey, accessToken);
      await prefs.remove(_legacyKey);
      if (refreshToken != null) {
        await prefs.setString(_refreshKey, refreshToken);
      }
      return;
    }
    await _secureStorage.write(key: _accessKey, value: accessToken);
    await _secureStorage.delete(key: _legacyKey);
    if (refreshToken != null) {
      await _secureStorage.write(key: _refreshKey, value: refreshToken);
    }
  }

  Future<void> clear() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_legacyKey);
      await prefs.remove(_accessKey);
      await prefs.remove(_refreshKey);
      return;
    }
    await _secureStorage.delete(key: _legacyKey);
    await _secureStorage.delete(key: _accessKey);
    await _secureStorage.delete(key: _refreshKey);
  }
}
