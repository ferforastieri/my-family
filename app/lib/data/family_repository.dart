import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../core/config/app_config.dart';
import '../core/socket/socket_client.dart';
import 'models.dart';

class FamilyRepository {
  FamilyRepository(this.socket);

  final SocketClient socket;

  Future<List<FamilyItem>> list(String resource) async {
    final rows = await socket.emitAck<List<dynamic>>('$resource.list');
    return rows
        .map((row) => FamilyItem(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<FamilyItem> create(String resource, Map<String, dynamic> data) async {
    final row =
        await socket.emitAck<Map<String, dynamic>>('$resource.create', data);
    return FamilyItem(Map<String, dynamic>.from(row));
  }

  Future<FamilyItem> update(
      String resource, String id, Map<String, dynamic> data) async {
    final row = await socket.emitAck<Map<String, dynamic>>(
        '$resource.update', {'id': id, 'data': data});
    return FamilyItem(Map<String, dynamic>.from(row));
  }

  Future<void> delete(String resource, String id) async {
    await socket.emitAck<Map<String, dynamic>>('$resource.delete', {'id': id});
  }

  Future<String> uploadPhotoFile(XFile file) async {
    final request =
        http.MultipartRequest('POST', AppConfig.apiUri('/fotos/upload'));
    final token = socket.token;
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    request.files.add(http.MultipartFile.fromBytes(
        'file', await file.readAsBytes(),
        filename: file.name));

    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(body.isEmpty ? 'Erro ao enviar arquivo.' : body);
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    final relativePath = json['relativePath']?.toString();
    if (relativePath == null || relativePath.isEmpty) {
      throw Exception('Resposta de upload inválida.');
    }
    return relativePath;
  }

  Future<List<QuizQuestion>> listQuizQuestions() async {
    final rows = await socket.emitAck<List<dynamic>>('games.quiz.list');
    return rows
        .map((row) =>
            QuizQuestion.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<List<QuizQuestion>> listQuizQuestionsAdmin() async {
    final rows = await socket.emitAck<List<dynamic>>('games.quiz.admin.list');
    return rows
        .map((row) =>
            QuizQuestion.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<QuizQuestion> createQuizQuestion(Map<String, dynamic> data) async {
    final row =
        await socket.emitAck<Map<String, dynamic>>('games.quiz.create', data);
    return QuizQuestion.fromJson(Map<String, dynamic>.from(row));
  }

  Future<QuizQuestion> updateQuizQuestion(
      String id, Map<String, dynamic> data) async {
    final row = await socket.emitAck<Map<String, dynamic>>(
        'games.quiz.update', {'id': id, 'data': data});
    return QuizQuestion.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteQuizQuestion(String id) async {
    await socket.emitAck<Map<String, dynamic>>('games.quiz.delete', {'id': id});
  }

  Future<List<GameWord>> listGameWords() async {
    final rows = await socket.emitAck<List<dynamic>>('games.words.list');
    return rows
        .map((row) => GameWord.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<List<GameWord>> listGameWordsAdmin() async {
    final rows = await socket.emitAck<List<dynamic>>('games.words.admin.list');
    return rows
        .map((row) => GameWord.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<GameWord> createGameWord(Map<String, dynamic> data) async {
    final row =
        await socket.emitAck<Map<String, dynamic>>('games.words.create', data);
    return GameWord.fromJson(Map<String, dynamic>.from(row));
  }

  Future<GameWord?> updateGameWord(String id, Map<String, dynamic> data) async {
    final row = await socket.emitAck<Map<String, dynamic>?>(
        'games.words.update', {'id': id, 'data': data});
    return row == null
        ? null
        : GameWord.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteGameWord(String id) async {
    await socket
        .emitAck<Map<String, dynamic>>('games.words.delete', {'id': id});
  }

  Future<void> completeGame({
    required String game,
    String? playerName,
    int? score,
    int? total,
  }) async {
    await socket.emitAck<Map<String, dynamic>>('games.complete', {
      'game': game,
      if (playerName != null && playerName.trim().isNotEmpty)
        'playerName': playerName.trim(),
      if (score != null) 'score': score,
      if (total != null) 'total': total,
    });
  }

  Future<List<GameStat>> gameStats() async {
    final rows = await socket.emitAck<List<dynamic>>('games.stats');
    return rows
        .map((row) => GameStat.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<List<AppUser>> listUsers() async {
    final rows = await socket.emitAck<List<dynamic>>('users.list');
    return rows
        .map((row) => AppUser.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<AppUser> updateUser(String id, Map<String, dynamic> data) async {
    final row = await socket
        .emitAck<Map<String, dynamic>>('users.update', {'id': id, ...data});
    return AppUser.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteUser(String id) async {
    await socket.emitAck<Map<String, dynamic>>('users.delete', {'id': id});
  }

  Future<List<AppNotification>> listNotificationsAdmin() async {
    final rows = await socket.emitAck<List<dynamic>>('notifications.list');
    return rows
        .map((row) =>
            AppNotification.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<AppNotification> createNotification(Map<String, dynamic> data) async {
    final row = await socket.emitAck<Map<String, dynamic>>(
        'notifications.create', data);
    return AppNotification.fromJson(Map<String, dynamic>.from(row));
  }

  Future<AppNotification?> updateNotification(
      String id, Map<String, dynamic> data) async {
    final row = await socket.emitAck<Map<String, dynamic>?>(
        'notifications.update', {'id': id, 'data': data});
    return row == null
        ? null
        : AppNotification.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteNotification(String id) async {
    await socket
        .emitAck<Map<String, dynamic>>('notifications.delete', {'id': id});
  }

  Future<void> clearNotifications() async {
    await socket.emitAck<Map<String, dynamic>>('notifications.clear');
  }

  Future<int> sendNotification({
    required String title,
    String? body,
    String? url,
  }) async {
    final row =
        await socket.emitAck<Map<String, dynamic>>('notifications.send', {
      'title': title,
      if (body != null) 'body': body,
      if (url != null) 'url': url,
    });
    return (row['sent'] as num?)?.toInt() ?? 0;
  }
}
