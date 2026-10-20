import 'dart:js_interop';

@JS('enableWebPush')
external JSPromise<JSAny?> _enableWebPush(JSString publicKey);

Future<Map<String, dynamic>?> subscribeWebPush(String publicKey) async {
  if (publicKey.isEmpty) return null;
  try {
    final result = await _enableWebPush(publicKey.toJS).toDart;
    if (result == null) return null;
    final value = result.dartify();
    return value is Map ? Map<String, dynamic>.from(value) : null;
  } catch (_) {
    return null;
  }
}
