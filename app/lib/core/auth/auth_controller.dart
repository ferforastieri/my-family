import 'package:flutter/foundation.dart';

import '../../data/models.dart';
import '../socket/socket_client.dart';
import 'token_store.dart';

class AuthController extends ChangeNotifier {
  AuthController(this.socket, this.tokenStore);

  final SocketClient socket;
  final TokenStore tokenStore;

  AppUser? user;
  bool loading = true;
  String? token;

  Future<void> bootstrap() async {
    token = await tokenStore.read();
    socket.connect(token: token);
    if (token != null) {
      try {
        final response = await socket.emitAck<Map<String, dynamic>>('auth.me');
        user = AppUser.fromJson(
            Map<String, dynamic>.from(response['user'] as Map));
      } catch (_) {
        await tokenStore.clear();
        token = null;
      }
    }
    loading = false;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    final response = await socket.emitAck<Map<String, dynamic>>('auth.login', {
      'email': email,
      'password': password,
    });
    await _acceptAuth(response);
  }

  Future<void> register(String email, String password, String name) async {
    final response =
        await socket.emitAck<Map<String, dynamic>>('auth.register', {
      'email': email,
      'password': password,
      'name': name,
    });
    await _acceptAuth(response);
  }

  Future<void> forgotPassword(String email) {
    return socket
        .emitAck<Map<String, dynamic>>('auth.forgotPassword', {'email': email});
  }

  Future<void> resetPassword(String token, String newPassword) {
    return socket.emitAck<Map<String, dynamic>>('auth.resetPassword', {
      'token': token,
      'newPassword': newPassword,
    });
  }

  Future<void> updateMe({required String name}) async {
    final response =
        await socket.emitAck<Map<String, dynamic>>('auth.updateMe', {
      'name': name,
    });
    final rawUser = response['user'];
    if (rawUser is Map) {
      user = AppUser.fromJson(Map<String, dynamic>.from(rawUser));
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    user = null;
    token = null;
    await tokenStore.clear();
    socket.connect();
    notifyListeners();
  }

  Future<void> _acceptAuth(Map<String, dynamic> response) async {
    token = (response['accessToken'] ?? response['access_token']) as String;
    user = AppUser.fromJson(Map<String, dynamic>.from(response['user'] as Map));
    await tokenStore.write(token!);
    socket.connect(token: token);
    notifyListeners();
  }
}
