class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.access,
    this.name,
    this.avatarPath,
    this.createdAt,
  });

  final String id;
  final String email;
  final String role;
  final List<String> access;
  final String? name;
  final String? avatarPath;
  final DateTime? createdAt;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'].toString(),
        email: json['email'] as String,
        role: (json['role'] ?? 'friends') as String,
        access: ((json['access'] as List?) ?? const [])
            .map((key) => key.toString())
            .where(appAccessKeys.contains)
            .toList(),
        name: json['name'] as String?,
        avatarPath: json['avatarPath'] as String?,
        createdAt: json['createdAt'] == null
            ? null
            : DateTime.tryParse(json['createdAt'].toString()),
      );

  bool get isAdmin => role == 'husband' || role == 'wife';

  bool canAccess(String key) => isAdmin || access.contains(key);
}

const appUserRoles = ['husband', 'wife', 'children', 'friends'];

const appAccessKeys = [
  'memorias',
  'playlist',
  'cartas',
  'jogos',
  'listas',
  'localizacao',
  'chat',
  'nossaHistoria',
];

class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int pages;

  bool get hasPrevious => page > 1;
  bool get hasNext => page < pages;
}

class FamilyItem {
  const FamilyItem(this.data);
  final Map<String, dynamic> data;

  String get id => data['id'].toString();
  String get title =>
      (data['titulo'] ?? data['title'] ?? data['url'] ?? 'Item').toString();
  String get subtitle => (data['conteudo'] ??
          data['artista'] ??
          data['body'] ??
          data['texto'] ??
          '')
      .toString();
  String get url => (data['url'] ?? '').toString();
  String get album {
    final value = (data['album'] ?? 'Geral').toString().trim();
    return value.isEmpty ? 'Geral' : value;
  }

  String get tipo => (data['tipo'] ?? 'imagem').toString();
}

class PhotoAlbumSummary {
  const PhotoAlbumSummary({
    required this.album,
    required this.count,
  });

  final String album;
  final int count;

  factory PhotoAlbumSummary.fromJson(Map<String, dynamic> json) {
    final value = (json['album'] ?? 'Geral').toString().trim();
    return PhotoAlbumSummary(
      album: value.isEmpty ? 'Geral' : value,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.url,
    required this.at,
  });

  final String id;
  final String title;
  final String body;
  final String url;
  final DateTime at;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'].toString(),
        title: (json['title'] ?? 'Nossa Família').toString(),
        body: (json['body'] ?? '').toString(),
        url: (json['url'] ?? '/').toString(),
        at: DateTime.fromMillisecondsSinceEpoch((json['at'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch),
      );
}

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.type,
    required this.title,
    required this.participantIds,
  });

  final String id;
  final String type;
  final String title;
  final List<String> participantIds;

  factory ChatConversation.fromJson(Map<String, dynamic> json) =>
      ChatConversation(
        id: json['id'].toString(),
        type: (json['type'] ?? 'global').toString(),
        title: (json['title'] ?? 'Chat').toString(),
        participantIds: ((json['participantIds'] as List?) ?? const [])
            .map((id) => id.toString())
            .toList(),
      );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderName,
    required this.at,
    this.senderId,
    this.text,
    this.mediaUrl,
    this.mediaType,
    this.readBy = const [],
    this.editedAt,
    this.deletedAt,
  });

  final String id;
  final String conversationId;
  final String? senderId;
  final String senderName;
  final String? text;
  final String? mediaUrl;
  final String? mediaType;
  final List<String> readBy;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final DateTime at;

  ChatMessage copyWith({List<String>? readBy}) => ChatMessage(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        text: text,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        readBy: readBy ?? this.readBy,
        editedAt: editedAt,
        deletedAt: deletedAt,
        at: at,
      );

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'].toString(),
        conversationId: json['conversationId'].toString(),
        senderId: json['senderId']?.toString(),
        senderName: (json['senderName'] ?? 'Visitante').toString(),
        text: json['text']?.toString(),
        mediaUrl: json['mediaUrl']?.toString(),
        mediaType: json['mediaType']?.toString(),
        readBy: ((json['readBy'] as List?) ?? const [])
            .map((id) => id.toString())
            .toList(),
        editedAt: json['editedAt'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                (json['editedAt'] as num).toInt()),
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                (json['deletedAt'] as num).toInt()),
        at: DateTime.fromMillisecondsSinceEpoch((json['at'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch),
      );
}

class ChatUser {
  const ChatUser({required this.id, required this.name, required this.email});

  final String id;
  final String? name;
  final String email;

  String get label => name?.isNotEmpty == true ? name! : email;

  factory ChatUser.fromJson(Map<String, dynamic> json) => ChatUser(
        id: json['id'].toString(),
        name: json['name']?.toString(),
        email: (json['email'] ?? '').toString(),
      );
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    this.correctIndex,
    this.active = true,
  });

  final String id;
  final String question;
  final List<String> options;
  final int? correctIndex;
  final bool active;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        id: json['id'].toString(),
        question: (json['question'] ?? '').toString(),
        options: ((json['options'] as List?) ?? const [])
            .map((option) => option.toString())
            .toList(),
        correctIndex: (json['correctIndex'] as num?)?.toInt(),
        active: json['active'] != false,
      );
}

class GameStat {
  const GameStat({
    required this.game,
    required this.playerName,
    required this.count,
    this.bestScore,
    this.lastAt,
  });

  final String game;
  final String playerName;
  final int count;
  final int? bestScore;
  final DateTime? lastAt;

  factory GameStat.fromJson(Map<String, dynamic> json) => GameStat(
        game: (json['game'] ?? '').toString(),
        playerName: (json['playerName'] ?? 'Visitante').toString(),
        count: (json['count'] as num?)?.toInt() ?? 0,
        bestScore: (json['bestScore'] as num?)?.toInt(),
        lastAt: json['lastAt'] is num
            ? DateTime.fromMillisecondsSinceEpoch(
                (json['lastAt'] as num).toInt())
            : null,
      );
}

class GameWord {
  const GameWord({
    required this.id,
    required this.word,
    this.active = true,
  });

  final String id;
  final String word;
  final bool active;

  factory GameWord.fromJson(Map<String, dynamic> json) => GameWord(
        id: json['id'].toString(),
        word: (json['word'] ?? '').toString(),
        active: json['active'] != false,
      );
}

class FamilyList {
  const FamilyList({
    required this.id,
    required this.title,
    this.description,
  });

  final String id;
  final String title;
  final String? description;

  factory FamilyList.fromJson(Map<String, dynamic> json) => FamilyList(
        id: json['id'].toString(),
        title: (json['title'] ?? 'Lista').toString(),
        description: json['description']?.toString(),
      );
}

class FamilyListItem {
  const FamilyListItem({
    required this.id,
    required this.listId,
    required this.text,
    required this.checked,
  });

  final String id;
  final String listId;
  final String text;
  final bool checked;

  factory FamilyListItem.fromJson(Map<String, dynamic> json) => FamilyListItem(
        id: json['id'].toString(),
        listId: json['listId'].toString(),
        text: (json['text'] ?? '').toString(),
        checked: json['checked'] == true,
      );
}

class LocationSnapshot {
  const LocationSnapshot({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.at,
    this.userName,
    this.accuracy,
    this.batteryLevel,
    this.isCharging,
    this.platform,
  });

  final String id;
  final String? userName;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final int? batteryLevel;
  final bool? isCharging;
  final String? platform;
  final DateTime at;

  factory LocationSnapshot.fromJson(Map<String, dynamic> json) =>
      LocationSnapshot(
        id: json['id'].toString(),
        userName: json['userName']?.toString(),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        batteryLevel: (json['batteryLevel'] as num?)?.toInt(),
        isCharging: json['isCharging'] as bool?,
        platform: json['platform']?.toString(),
        at: json['createdAt'] is String
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}

class LocationPlace {
  const LocationPlace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.active,
    this.description,
  });

  final String id;
  final String name;
  final String? description;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final bool active;

  factory LocationPlace.fromJson(Map<String, dynamic> json) => LocationPlace(
        id: json['id'].toString(),
        name: (json['name'] ?? 'Local').toString(),
        description: json['description']?.toString(),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        radiusMeters: (json['radiusMeters'] as num?)?.toInt() ?? 120,
        active: json['active'] != false,
      );
}
