import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  static const _key = 'my_family_token';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<String?> read() async {
    if (kIsWeb) return (await SharedPreferences.getInstance()).getString(_key);
    return _secureStorage.read(key: _key);
  }

  Future<void> write(String token) async {
    if (kIsWeb) {
      await (await SharedPreferences.getInstance()).setString(_key, token);
      return;
    }
    await _secureStorage.write(key: _key, value: token);
  }

  Future<void> clear() async {
    if (kIsWeb) {
      await (await SharedPreferences.getInstance()).remove(_key);
      return;
    }
    await _secureStorage.delete(key: _key);
  }
}
