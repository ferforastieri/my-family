import '../config/app_config.dart';
import 'cookie_transport.dart';

Map<String, String> _mediaHeaders = const {};

Map<String, String> authenticatedMediaHeaders() => _mediaHeaders;

Future<void> refreshAuthenticatedMediaHeaders() async {
  _mediaHeaders = await sessionCookies.headers(AppConfig.apiUri('/'));
}

Future<void> clearAuthenticatedMediaHeaders() async {
  _mediaHeaders = const {};
  await sessionCookies.clear();
}
