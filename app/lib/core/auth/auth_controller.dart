import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../data/models.dart';
import '../api/socket_api_client.dart';
import '../config/app_config.dart';
import '../socket/socket_client.dart';
import 'token_store.dart';

class AuthController extends ChangeNotifier {
  AuthController(this.socket, this.tokenStore);

  final SocketClient socket;
  final TokenStore tokenStore;
  late final SocketApiClient api = SocketApiClient(socket);

  AppUser? user;
  bool loading = true;
  String? token;

  Future<void> bootstrap() async {
    token = await tokenStore.read();
    socket.connect(token: token);
    if (token != null) {
      try {
        final response = await api.query<Map<String, dynamic>>('auth.me');
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
    final response = await api.mutate<Map<String, dynamic>>('auth.login', {
      'email': email,
      'password': password,
    });
    await _acceptAuth(response);
  }

  Future<void> register(String email, String password, String name) async {
    final response = await api.mutate<Map<String, dynamic>>('auth.register', {
      'email': email,
      'password': password,
      'name': name,
    });
    await _acceptAuth(response);
  }

  Future<void> forgotPassword(String email) {
    return api
        .mutate<Map<String, dynamic>>('auth.forgotPassword', {'email': email});
  }

  Future<void> resetPassword(String token, String newPassword) {
    return api.mutate<Map<String, dynamic>>('auth.resetPassword', {
      'token': token,
      'newPassword': newPassword,
    });
  }

  Future<void> updateMe({required String name}) async {
    final response = await api.mutate<Map<String, dynamic>>('auth.updateMe', {
      'name': name,
    });
    final rawUser = response['user'];
    if (rawUser is Map) {
      user = AppUser.fromJson(Map<String, dynamic>.from(rawUser));
      notifyListeners();
    }
  }

  Future<void> refreshMe() async {
    if (token == null) return;
    final response = await api.query<Map<String, dynamic>>('auth.me');
    final rawUser = response['user'];
    if (rawUser is Map) {
      user = AppUser.fromJson(Map<String, dynamic>.from(rawUser));
      notifyListeners();
    }
  }

  Future<void> updateAvatar(XFile file) async {
    final currentToken = token;
    if (currentToken == null) {
      throw Exception('Entre para alterar sua foto.');
    }
    final request = http.MultipartRequest(
      'POST',
      AppConfig.apiUri('/auth/avatar'),
    );
    request.headers['Authorization'] = 'Bearer $currentToken';
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      await file.readAsBytes(),
      filename: file.name,
    ));

    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(body.isEmpty ? 'Erro ao enviar avatar.' : body);
    }

    final raw = await compute(_decodeJsonMap, body);
    final rawUser = raw['user'];
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
    await socket.ensureConnected(token: token);
    notifyListeners();
  }
}

Map<String, dynamic> _decodeJsonMap(String body) {
  return Map<String, dynamic>.from(
      const JsonDecoder().convert(body) as Map<dynamic, dynamic>);
}
