import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../core/config/app_config.dart';
import '../core/socket/socket_client.dart';
import 'models.dart';

class FamilyRepository {
  FamilyRepository(this.socket);

  final SocketClient socket;

  Future<PaginatedResult<FamilyItem>> listPage(
    String resource,
    int page,
    int limit, {
    String? titlePrefix,
  }) async {
    final data = await socket.emitAck<dynamic>('$resource.list', {
      'page': page,
      'limit': limit,
      if (titlePrefix != null) 'titlePrefix': titlePrefix,
    });
    return _paginated(
        data, (row) => FamilyItem(Map<String, dynamic>.from(row)));
  }

  Future<List<FamilyItem>> list(String resource) async {
    return (await listPage(resource, 1, 24)).items;
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
    return (await listQuizQuestionsPage(1, 20)).items;
  }

  Future<PaginatedResult<QuizQuestion>> listQuizQuestionsPage(
      int page, int limit) async {
    final data = await socket
        .emitAck<dynamic>('games.quiz.list', {'page': page, 'limit': limit});
    return _paginated(
        data, (row) => QuizQuestion.fromJson(Map<String, dynamic>.from(row)));
  }

  Future<List<QuizQuestion>> listQuizQuestionsAdmin() async {
    return (await listQuizQuestionsAdminPage(1, 20)).items;
  }

  Future<PaginatedResult<QuizQuestion>> listQuizQuestionsAdminPage(
      int page, int limit) async {
    final data = await socket.emitAck<dynamic>(
        'games.quiz.admin.list', {'page': page, 'limit': limit});
    return _paginated(
        data, (row) => QuizQuestion.fromJson(Map<String, dynamic>.from(row)));
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
    return (await listGameWordsPage(1, 30)).items;
  }

  Future<PaginatedResult<GameWord>> listGameWordsPage(
      int page, int limit) async {
    final data = await socket
        .emitAck<dynamic>('games.words.list', {'page': page, 'limit': limit});
    return _paginated(
        data, (row) => GameWord.fromJson(Map<String, dynamic>.from(row)));
  }

  Future<List<GameWord>> listGameWordsAdmin() async {
    return (await listGameWordsAdminPage(1, 30)).items;
  }

  Future<PaginatedResult<GameWord>> listGameWordsAdminPage(
      int page, int limit) async {
    final data = await socket.emitAck<dynamic>(
        'games.words.admin.list', {'page': page, 'limit': limit});
    return _paginated(
        data, (row) => GameWord.fromJson(Map<String, dynamic>.from(row)));
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
    return (await gameStatsPage(1, 20)).items;
  }

  Future<PaginatedResult<GameStat>> gameStatsPage(int page, int limit) async {
    final data = await socket
        .emitAck<dynamic>('games.stats', {'page': page, 'limit': limit});
    return _paginated(
      data,
      (row) => GameStat.fromJson(Map<String, dynamic>.from(row)),
    );
  }

  Future<List<AppUser>> listUsers() async {
    return (await listUsersPage(1, 20)).items;
  }

  Future<PaginatedResult<AppUser>> listUsersPage(int page, int limit) async {
    final data = await socket
        .emitAck<dynamic>('users.list', {'page': page, 'limit': limit});
    return _paginated(
        data, (row) => AppUser.fromJson(Map<String, dynamic>.from(row)));
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
    return (await listNotificationsAdminPage(1, 30)).items;
  }

  Future<PaginatedResult<AppNotification>> listNotificationsAdminPage(
      int page, int limit) async {
    final data = await socket
        .emitAck<dynamic>('notifications.list', {'page': page, 'limit': limit});
    return _paginated(data,
        (row) => AppNotification.fromJson(Map<String, dynamic>.from(row)));
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

  Future<void> scheduleNotification({
    required String title,
    String? body,
    String? url,
    required DateTime scheduledAt,
  }) async {
    await socket.emitAck<Map<String, dynamic>>('notifications.schedule', {
      'title': title,
      if (body != null) 'body': body,
      if (url != null) 'url': url,
      'scheduledAt': scheduledAt.toIso8601String(),
    });
  }

  Future<List<FamilyList>> listFamilyLists() async {
    return (await listFamilyListsPage(1, 20)).items;
  }

  Future<PaginatedResult<FamilyList>> listFamilyListsPage(
      int page, int limit) async {
    final data = await socket
        .emitAck<dynamic>('lists.list', {'page': page, 'limit': limit});
    return _paginated(
        data, (row) => FamilyList.fromJson(Map<String, dynamic>.from(row)));
  }

  Future<FamilyList> createFamilyList(Map<String, dynamic> data) async {
    final row =
        await socket.emitAck<Map<String, dynamic>>('lists.create', data);
    return FamilyList.fromJson(Map<String, dynamic>.from(row));
  }

  Future<FamilyList?> updateFamilyList(
      String id, Map<String, dynamic> data) async {
    final row = await socket.emitAck<Map<String, dynamic>?>(
        'lists.update', {'id': id, 'data': data});
    return row == null
        ? null
        : FamilyList.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteFamilyList(String id) async {
    await socket.emitAck<Map<String, dynamic>>('lists.delete', {'id': id});
  }

  Future<List<FamilyListItem>> listFamilyListItems(String listId) async {
    return (await listFamilyListItemsPage(listId, 1, 50)).items;
  }

  Future<PaginatedResult<FamilyListItem>> listFamilyListItemsPage(
      String listId, int page, int limit) async {
    final data = await socket.emitAck<dynamic>(
        'lists.items', {'listId': listId, 'page': page, 'limit': limit});
    return _paginated(
        data, (row) => FamilyListItem.fromJson(Map<String, dynamic>.from(row)));
  }

  Future<FamilyListItem> createFamilyListItem(
      String listId, String text) async {
    final row =
        await socket.emitAck<Map<String, dynamic>>('lists.items.create', {
      'listId': listId,
      'text': text,
    });
    return FamilyListItem.fromJson(Map<String, dynamic>.from(row));
  }

  Future<FamilyListItem?> updateFamilyListItem(
      String id, Map<String, dynamic> data) async {
    final row = await socket.emitAck<Map<String, dynamic>?>(
        'lists.items.update', {'id': id, 'data': data});
    return row == null
        ? null
        : FamilyListItem.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteFamilyListItem(String id) async {
    await socket
        .emitAck<Map<String, dynamic>>('lists.items.delete', {'id': id});
  }

  Future<List<LocationSnapshot>> listLocations() async {
    final data = await socket
        .emitAck<dynamic>('location.latest', {'page': 1, 'limit': 50});
    return _paginated(data,
            (row) => LocationSnapshot.fromJson(Map<String, dynamic>.from(row)))
        .items;
  }

  PaginatedResult<T> _paginated<T>(
      dynamic data, T Function(Map<String, dynamic> row) mapper) {
    if (data is List) {
      return PaginatedResult<T>(
        items: data
            .map((row) => mapper(Map<String, dynamic>.from(row as Map)))
            .toList(),
        page: 1,
        limit: data.length,
        total: data.length,
        pages: 1,
      );
    }
    final map = Map<String, dynamic>.from(data as Map);
    final rows = ((map['items'] as List?) ?? const []);
    return PaginatedResult<T>(
      items: rows
          .map((row) => mapper(Map<String, dynamic>.from(row as Map)))
          .toList(),
      page: (map['page'] as num?)?.toInt() ?? 1,
      limit: (map['limit'] as num?)?.toInt() ?? rows.length,
      total: (map['total'] as num?)?.toInt() ?? rows.length,
      pages: (map['pages'] as num?)?.toInt() ?? 1,
    );
  }
}
