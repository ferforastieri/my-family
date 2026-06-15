import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../core/config/app_config.dart';
import '../core/api/socket_api_client.dart';
import '../core/socket/socket_client.dart';
import 'models.dart';

class FamilyRepository {
  FamilyRepository(this.socket);

  final SocketClient socket;
  late final SocketApiClient api = SocketApiClient(socket);

  String? takeMessage() => socket.takeLastMessage();

  Future<PaginatedResult<FamilyItem>> listPage(
    String resource,
    int page,
    int limit, {
    String? album,
  }) async {
    final data = await api.query<dynamic>('$resource.list', {
      'page': page,
      'limit': limit,
      if (album != null && album.trim().isNotEmpty) 'album': album.trim(),
    });
    return _paginated(
        data, (row) => FamilyItem(Map<String, dynamic>.from(row)));
  }

  Future<List<PhotoAlbumSummary>> listPhotoAlbums() async {
    final rows = await api.query<List<dynamic>>('fotos.albums');
    return rows
        .map((row) =>
            PhotoAlbumSummary.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<List<FamilyItem>> list(String resource) async {
    return (await listPage(resource, 1, 24)).items;
  }

  Future<FamilyItem> create(String resource, Map<String, dynamic> data) async {
    final row =
        await api.mutate<Map<String, dynamic>>('$resource.create', data);
    return FamilyItem(Map<String, dynamic>.from(row));
  }

  Future<FamilyItem> update(
      String resource, String id, Map<String, dynamic> data) async {
    final row = await api.mutate<Map<String, dynamic>>(
        '$resource.update', {'id': id, 'data': data});
    return FamilyItem(Map<String, dynamic>.from(row));
  }

  Future<void> delete(String resource, String id) async {
    await api.mutate<Map<String, dynamic>>('$resource.delete', {'id': id});
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
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final message = json['message'];
    if (message is String) socket.rememberMessage(message);
    final relativePath = data['relativePath']?.toString();
    if (relativePath == null || relativePath.isEmpty) {
      throw Exception(json['message']?.toString() ?? body);
    }
    return relativePath;
  }

  Future<List<QuizQuestion>> listQuizQuestions() async {
    return (await listQuizQuestionsPage(1, 20)).items;
  }

  Future<PaginatedResult<QuizQuestion>> listQuizQuestionsPage(
      int page, int limit) async {
    final data = await api
        .query<dynamic>('games.quiz.list', {'page': page, 'limit': limit});
    return _paginated(
        data, (row) => QuizQuestion.fromJson(Map<String, dynamic>.from(row)));
  }

  Future<List<QuizQuestion>> listQuizQuestionsAdmin() async {
    return (await listQuizQuestionsAdminPage(1, 20)).items;
  }

  Future<PaginatedResult<QuizQuestion>> listQuizQuestionsAdminPage(
      int page, int limit) async {
    final data = await api.query<dynamic>(
        'games.quiz.admin.list', {'page': page, 'limit': limit});
    return _paginated(
        data, (row) => QuizQuestion.fromJson(Map<String, dynamic>.from(row)));
  }

  Future<QuizQuestion> createQuizQuestion(Map<String, dynamic> data) async {
    final row =
        await api.mutate<Map<String, dynamic>>('games.quiz.create', data);
    return QuizQuestion.fromJson(Map<String, dynamic>.from(row));
  }

  Future<QuizQuestion> updateQuizQuestion(
      String id, Map<String, dynamic> data) async {
    final row = await api.mutate<Map<String, dynamic>>(
        'games.quiz.update', {'id': id, 'data': data});
    return QuizQuestion.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteQuizQuestion(String id) async {
    await api.mutate<Map<String, dynamic>>('games.quiz.delete', {'id': id});
  }

  Future<List<GameWord>> listGameWords() async {
    return (await listGameWordsPage(1, 30)).items;
  }

  Future<PaginatedResult<GameWord>> listGameWordsPage(
      int page, int limit) async {
    final data = await api
        .query<dynamic>('games.words.list', {'page': page, 'limit': limit});
    return _paginated(
        data, (row) => GameWord.fromJson(Map<String, dynamic>.from(row)));
  }

  Future<List<GameWord>> listGameWordsAdmin() async {
    return (await listGameWordsAdminPage(1, 30)).items;
  }

  Future<PaginatedResult<GameWord>> listGameWordsAdminPage(
      int page, int limit) async {
    final data = await api.query<dynamic>(
        'games.words.admin.list', {'page': page, 'limit': limit});
    return _paginated(
        data, (row) => GameWord.fromJson(Map<String, dynamic>.from(row)));
  }

  Future<GameWord> createGameWord(Map<String, dynamic> data) async {
    final row =
        await api.mutate<Map<String, dynamic>>('games.words.create', data);
    return GameWord.fromJson(Map<String, dynamic>.from(row));
  }

  Future<GameWord?> updateGameWord(String id, Map<String, dynamic> data) async {
    final row = await api.mutate<Map<String, dynamic>?>(
        'games.words.update', {'id': id, 'data': data});
    return row == null
        ? null
        : GameWord.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteGameWord(String id) async {
    await api.mutate<Map<String, dynamic>>('games.words.delete', {'id': id});
  }

  Future<List<MiniGameConfig>> listMiniGames() async {
    return (await listMiniGamesPage(1, 30)).items;
  }

  Future<PaginatedResult<MiniGameConfig>> listMiniGamesPage(
      int page, int limit) async {
    final data = await api
        .query<dynamic>('games.mini.list', {'page': page, 'limit': limit});
    return _paginated(
      data,
      (row) => MiniGameConfig.fromJson(Map<String, dynamic>.from(row)),
    );
  }

  Future<PaginatedResult<MiniGameConfig>> listMiniGamesAdminPage(
      int page, int limit) async {
    final data = await api.query<dynamic>(
        'games.mini.admin.list', {'page': page, 'limit': limit});
    return _paginated(
      data,
      (row) => MiniGameConfig.fromJson(Map<String, dynamic>.from(row)),
    );
  }

  Future<MiniGameConfig> createMiniGame(Map<String, dynamic> data) async {
    final row =
        await api.mutate<Map<String, dynamic>>('games.mini.create', data);
    return MiniGameConfig.fromJson(Map<String, dynamic>.from(row));
  }

  Future<MiniGameConfig?> updateMiniGame(
      String id, Map<String, dynamic> data) async {
    final row = await api.mutate<Map<String, dynamic>?>(
        'games.mini.update', {'id': id, 'data': data});
    return row == null
        ? null
        : MiniGameConfig.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteMiniGame(String id) async {
    await api.mutate<Map<String, dynamic>>('games.mini.delete', {'id': id});
  }

  Future<void> completeGame({
    required String game,
    String? playerName,
    int? score,
    int? total,
  }) async {
    await api.mutate<Map<String, dynamic>>('games.complete', {
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
    final data =
        await api.query<dynamic>('games.stats', {'page': page, 'limit': limit});
    return _paginated(
      data,
      (row) => GameStat.fromJson(Map<String, dynamic>.from(row)),
    );
  }

  Future<List<AppUser>> listUsers() async {
    return (await listUsersPage(1, 20)).items;
  }

  Future<PaginatedResult<AppUser>> listUsersPage(int page, int limit) async {
    final data =
        await api.query<dynamic>('users.list', {'page': page, 'limit': limit});
    return _paginated(
        data, (row) => AppUser.fromJson(Map<String, dynamic>.from(row)));
  }

  Future<AppUser> updateUser(String id, Map<String, dynamic> data) async {
    final row = await api
        .mutate<Map<String, dynamic>>('users.update', {'id': id, ...data});
    return AppUser.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteUser(String id) async {
    await api.mutate<Map<String, dynamic>>('users.delete', {'id': id});
  }

  Future<List<AppNotification>> listNotificationsAdmin() async {
    return (await listNotificationsAdminPage(1, 30)).items;
  }

  Future<PaginatedResult<AppNotification>> listNotificationsAdminPage(
      int page, int limit) async {
    final data = await api.query<dynamic>('notifications.list', {
      'page': page,
      'limit': limit,
      'type': 'manual',
    });
    return _paginated(data,
        (row) => AppNotification.fromJson(Map<String, dynamic>.from(row)));
  }

  Future<AppNotification> createNotification(Map<String, dynamic> data) async {
    final row =
        await api.mutate<Map<String, dynamic>>('notifications.create', data);
    return AppNotification.fromJson(Map<String, dynamic>.from(row));
  }

  Future<AppNotification?> updateNotification(
      String id, Map<String, dynamic> data) async {
    final row = await api.mutate<Map<String, dynamic>?>(
        'notifications.update', {'id': id, 'data': data});
    return row == null
        ? null
        : AppNotification.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteNotification(String id) async {
    await api.mutate<Map<String, dynamic>>('notifications.delete', {'id': id});
  }

  Future<void> clearNotifications() async {
    await api.mutate<Map<String, dynamic>>('notifications.clear');
  }

  Future<int> sendNotification({
    required String title,
    String? body,
    String? url,
  }) async {
    final row = await api.mutate<Map<String, dynamic>>('notifications.send', {
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
    await api.mutate<Map<String, dynamic>>('notifications.schedule', {
      'title': title,
      if (body != null) 'body': body,
      if (url != null) 'url': url,
      'scheduledAt': scheduledAt.toUtc().toIso8601String(),
    });
  }

  Future<List<ScheduledNotification>> listScheduledNotifications() async {
    final data = await api.query<dynamic>('notifications.scheduled.list', {
      'page': 1,
      'limit': 30,
    });
    final page = _paginated(
      data,
      (row) => ScheduledNotification.fromJson(
        Map<String, dynamic>.from(row),
      ),
    );
    return page.items;
  }

  Future<void> deleteScheduledNotification(String id) async {
    await api.mutate<Map<String, dynamic>>(
      'notifications.scheduled.delete',
      {'id': id},
    );
  }

  Future<List<FamilyList>> listFamilyLists() async {
    return (await listFamilyListsPage(1, 20)).items;
  }

  Future<PaginatedResult<FamilyList>> listFamilyListsPage(
      int page, int limit) async {
    final data =
        await api.query<dynamic>('lists.list', {'page': page, 'limit': limit});
    return _paginated(
        data, (row) => FamilyList.fromJson(Map<String, dynamic>.from(row)));
  }

  Future<FamilyList> createFamilyList(Map<String, dynamic> data) async {
    final row = await api.mutate<Map<String, dynamic>>('lists.create', data);
    return FamilyList.fromJson(Map<String, dynamic>.from(row));
  }

  Future<FamilyList?> updateFamilyList(
      String id, Map<String, dynamic> data) async {
    final row = await api.mutate<Map<String, dynamic>?>(
        'lists.update', {'id': id, 'data': data});
    return row == null
        ? null
        : FamilyList.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteFamilyList(String id) async {
    await api.mutate<Map<String, dynamic>>('lists.delete', {'id': id});
  }

  Future<List<FamilyListItem>> listFamilyListItems(String listId) async {
    return (await listFamilyListItemsPage(listId, 1, 50)).items;
  }

  Future<PaginatedResult<FamilyListItem>> listFamilyListItemsPage(
      String listId, int page, int limit) async {
    final data = await api.query<dynamic>(
        'lists.items', {'listId': listId, 'page': page, 'limit': limit});
    return _paginated(
        data, (row) => FamilyListItem.fromJson(Map<String, dynamic>.from(row)));
  }

  Future<FamilyListItem> createFamilyListItem(
      String listId, String text) async {
    final row = await api.mutate<Map<String, dynamic>>('lists.items.create', {
      'listId': listId,
      'text': text,
    });
    return FamilyListItem.fromJson(Map<String, dynamic>.from(row));
  }

  Future<FamilyListItem?> updateFamilyListItem(
      String id, Map<String, dynamic> data) async {
    final row = await api.mutate<Map<String, dynamic>?>(
        'lists.items.update', {'id': id, 'data': data});
    return row == null
        ? null
        : FamilyListItem.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteFamilyListItem(String id) async {
    await api.mutate<Map<String, dynamic>>('lists.items.delete', {'id': id});
  }

  Future<List<LocationSnapshot>> listLocations() async {
    final data =
        await api.query<dynamic>('location.latest', {'page': 1, 'limit': 50});
    return _paginated(data,
            (row) => LocationSnapshot.fromJson(Map<String, dynamic>.from(row)))
        .items;
  }

  Future<List<LocationPlace>> listLocationPlaces() async {
    final data = await api.query<List<dynamic>>('location.places');
    return data
        .map((row) =>
            LocationPlace.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<LocationPlace> createLocationPlace(Map<String, dynamic> data) async {
    final row =
        await api.mutate<Map<String, dynamic>>('location.places.create', data);
    return LocationPlace.fromJson(Map<String, dynamic>.from(row));
  }

  Future<LocationPlace?> updateLocationPlace(
      String id, Map<String, dynamic> data) async {
    final row = await api.mutate<Map<String, dynamic>?>(
        'location.places.update', {'id': id, 'data': data});
    return row == null
        ? null
        : LocationPlace.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteLocationPlace(String id) async {
    await api
        .mutate<Map<String, dynamic>>('location.places.delete', {'id': id});
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
