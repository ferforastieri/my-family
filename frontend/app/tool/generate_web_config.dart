import 'dart:convert';
import 'dart:io';

void main() {
  const names = {
    'apiKey': 'FIREBASE_API_KEY',
    'appId': 'FIREBASE_APP_ID',
    'messagingSenderId': 'FIREBASE_MESSAGING_SENDER_ID',
    'projectId': 'FIREBASE_PROJECT_ID',
    'authDomain': 'FIREBASE_AUTH_DOMAIN',
    'storageBucket': 'FIREBASE_STORAGE_BUCKET',
  };
  final config = <String, String>{};
  for (final entry in names.entries) {
    final value = Platform.environment[entry.value];
    if (value != null && value.isNotEmpty) config[entry.key] = value;
  }
  final required = ['apiKey', 'appId', 'messagingSenderId', 'projectId'];
  final payload =
      required.every(config.containsKey) ? jsonEncode(config) : 'null';
  File('web/firebase-config.js')
      .writeAsStringSync('self.firebaseConfig = $payload;\n');
}
