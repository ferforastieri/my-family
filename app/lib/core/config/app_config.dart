class AppConfig {
  static const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _socketUrl = String.fromEnvironment('SOCKET_URL');
  static const _publicWebUrl = String.fromEnvironment('PUBLIC_WEB_URL');

  static String get apiBaseUrl => _requiredEnv('API_BASE_URL', _apiBaseUrl);
  static String get socketUrl => _requiredEnv('SOCKET_URL', _socketUrl);
  static String get publicWebUrl {
    if (_publicWebUrl.trim().isNotEmpty) return _publicWebUrl;
    return Uri.base.hasScheme ? Uri.base.origin : '';
  }

  static const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const firebaseMessagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const firebaseProjectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const firebaseAuthDomain =
      String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const firebaseStorageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const firebaseWebPushCertificateKey =
      String.fromEnvironment('FIREBASE_WEB_PUSH_CERTIFICATE_KEY');

  static bool get hasFirebaseConfig {
    return firebaseApiKey.isNotEmpty &&
        firebaseAppId.isNotEmpty &&
        firebaseMessagingSenderId.isNotEmpty &&
        firebaseProjectId.isNotEmpty;
  }

  static Uri apiUri(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$apiBaseUrl$normalized');
  }

  static Uri publicSiteUri(String slug, {String locale = 'pt'}) {
    return Uri.parse('$publicWebUrl/$locale/familia/$slug');
  }

  static String _requiredEnv(String name, String value) {
    if (value.trim().isEmpty) {
      throw StateError('$name não foi configurada no build.');
    }
    return value;
  }
}
