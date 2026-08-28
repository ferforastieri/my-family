import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CookieTransport {
  PersistCookieJar? _jar;

  Future<PersistCookieJar> _cookies() async {
    final current = _jar;
    if (current != null) return current;
    final jar = PersistCookieJar(
      ignoreExpires: false,
      storage: SecureCookieStorage(),
    );
    _jar = jar;
    return jar;
  }

  Future<void> configure(Dio dio) async {
    dio.interceptors.add(CookieManager(await _cookies()));
  }

  Future<Map<String, String>> headers(Uri uri) async {
    final cookies = await (await _cookies()).loadForRequest(uri);
    if (cookies.isEmpty) return const {};
    return {
      'Cookie': cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; '),
    };
  }

  Future<void> clear() async => (await _cookies()).deleteAll();
}

final sessionCookies = CookieTransport();

class SecureCookieStorage extends Storage {
  static const _prefix = 'cookie_jar:';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {}

  @override
  Future<String?> read(String key) => _storage.read(key: '$_prefix$key');

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: '$_prefix$key', value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: '$_prefix$key');

  @override
  Future<void> deleteAll(List<String> keys) async {
    for (final key in keys) {
      await delete(key);
    }
  }
}
