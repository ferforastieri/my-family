import 'package:dio/dio.dart';
import 'package:dio/browser.dart';

class CookieTransport {
  Future<void> configure(Dio dio) async {
    (dio.httpClientAdapter as BrowserHttpClientAdapter).withCredentials = true;
  }

  Future<Map<String, String>> headers(Uri uri) async => const {};

  Future<void> clear() async {}
}

final sessionCookies = CookieTransport();
