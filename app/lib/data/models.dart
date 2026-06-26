class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.access,
    this.platformRole,
    this.name,
    this.avatarPath,
    this.createdAt,
    this.tenantId,
    this.tenantSlug,
  });

  final String id;
  final String email;
  final String role;
  final String? platformRole;
  final List<String> access;
  final String? name;
  final String? avatarPath;
  final DateTime? createdAt;
  final String? tenantId;
  final String? tenantSlug;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'].toString(),
        email: json['email'] as String,
        role: (json['role'] ?? 'member') as String,
        platformRole: json['platformRole']?.toString(),
        access: ((json['access'] as List?) ?? const [])
            .map((key) => key.toString())
            .where(appAccessKeys.contains)
            .toList(),
        name: json['name'] as String?,
        avatarPath: json['avatarPath'] as String?,
        createdAt: json['createdAt'] == null
            ? null
            : DateTime.tryParse(json['createdAt'].toString()),
        tenantId: json['tenantId']?.toString(),
        tenantSlug: json['tenantSlug']?.toString(),
      );

  bool get isAdmin => role == 'owner' || role == 'admin';
  bool get isPlatformAdmin => platformRole == 'admin';

  bool canAccess(String key) => isAdmin || access.contains(key);
}

const appUserRoles = ['owner', 'admin', 'member'];

class TenantInfo {
  const TenantInfo({
    required this.id,
    required this.name,
    required this.slug,
    required this.status,
    required this.defaultLocale,
    required this.isPublished,
    required this.isDemo,
  });

  final String id;
  final String name;
  final String slug;
  final String status;
  final String defaultLocale;
  final bool isPublished;
  final bool isDemo;

  bool get isActive => status == 'active' || isDemo;

  factory TenantInfo.fromJson(Map<String, dynamic> json) => TenantInfo(
        id: json['id'].toString(),
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        status: json['status']?.toString() ?? 'pending_payment',
        defaultLocale: json['defaultLocale']?.toString() ?? 'pt-BR',
        isPublished: json['isPublished'] == true,
        isDemo: json['isDemo'] == true,
      );
}

class TenantMembershipOption {
  const TenantMembershipOption({
    required this.tenant,
    required this.role,
    required this.access,
    this.relationLabel,
  });

  final TenantInfo tenant;
  final String role;
  final List<String> access;
  final String? relationLabel;

  factory TenantMembershipOption.fromJson(Map<String, dynamic> json) {
    final rawTenant = json['tenant'];
    final rawMembership = json['membership'];
    final membership = rawMembership is Map
        ? Map<String, dynamic>.from(rawMembership)
        : const <String, dynamic>{};
    return TenantMembershipOption(
      tenant: TenantInfo.fromJson(Map<String, dynamic>.from(rawTenant as Map)),
      role: membership['role']?.toString() ?? 'member',
      access: ((membership['access'] as List?) ?? const [])
          .map((key) => key.toString())
          .where(appAccessKeys.contains)
          .toList(),
      relationLabel: membership['relationLabel']?.toString(),
    );
  }
}

const appAccessKeys = [
  'memorias',
  'playlist',
  'cartas',
  'jogos',
  'listas',
  'notas',
  'localizacao',
  'chat',
  'nossaHistoria',
];

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.interval,
    required this.name,
    required this.description,
    required this.priceCents,
    required this.currency,
    required this.active,
    required this.highlighted,
    required this.sortOrder,
    this.stripePriceId,
  });

  final String id;
  final String interval;
  final String name;
  final String description;
  final int priceCents;
  final String currency;
  final bool active;
  final bool highlighted;
  final int sortOrder;
  final String? stripePriceId;

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) =>
      SubscriptionPlan(
        id: json['id']?.toString() ?? json['interval']?.toString() ?? '',
        interval: json['interval']?.toString() ?? 'monthly',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        priceCents: (json['priceCents'] as num?)?.toInt() ?? 0,
        currency: json['currency']?.toString() ?? 'BRL',
        active: json['active'] != false,
        highlighted: json['highlighted'] == true,
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
        stripePriceId: json['stripePriceId']?.toString(),
      );
}

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
    this.read = false,
    this.type = 'manual',
  });

  final String id;
  final String title;
  final String body;
  final String url;
  final DateTime at;
  final bool read;
  final String type;

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        url: url,
        at: at,
        read: read ?? this.read,
        type: type,
      );

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'].toString(),
        title: (json['title'] ?? 'Nossa Família').toString(),
        body: (json['body'] ?? '').toString(),
        url: (json['url'] ?? '/').toString(),
        read: json['read'] == true,
        type: (json['type'] ?? 'manual').toString(),
        at: DateTime.fromMillisecondsSinceEpoch((json['at'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch),
      );
}

class ScheduledNotification {
  const ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.url,
    required this.scheduledAt,
    required this.status,
    this.sentAt,
    this.error,
  });

  final String id;
  final String title;
  final String body;
  final String url;
  final DateTime scheduledAt;
  final String status;
  final DateTime? sentAt;
  final String? error;

  factory ScheduledNotification.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is num) {
        return DateTime.fromMillisecondsSinceEpoch(value.toInt());
      }
      return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
    }

    return ScheduledNotification(
      id: json['id'].toString(),
      title: (json['title'] ?? 'Nossa Família').toString(),
      body: (json['body'] ?? '').toString(),
      url: (json['url'] ?? '/').toString(),
      scheduledAt: parseDate(json['scheduledAt']),
      status: (json['status'] ?? 'pending').toString(),
      sentAt: json['sentAt'] == null ? null : parseDate(json['sentAt']),
      error: json['error']?.toString(),
    );
  }
}

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.type,
    required this.title,
    required this.participantIds,
    this.unreadCount = 0,
    this.avatarPath,
  });

  final String id;
  final String type;
  final String title;
  final List<String> participantIds;
  final int unreadCount;
  final String? avatarPath;

  ChatConversation copyWith({int? unreadCount}) => ChatConversation(
        id: id,
        type: type,
        title: title,
        participantIds: participantIds,
        unreadCount: unreadCount ?? this.unreadCount,
        avatarPath: avatarPath,
      );

  factory ChatConversation.fromJson(Map<String, dynamic> json) =>
      ChatConversation(
        id: json['id'].toString(),
        type: (json['type'] ?? 'global').toString(),
        title: (json['title'] ?? 'Chat').toString(),
        unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
        avatarPath: json['avatarPath']?.toString(),
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
    this.senderAvatarPath,
    this.text,
    this.mediaUrl,
    this.mediaType,
    this.replyToMessageId,
    this.replyToMessage,
    this.readBy = const [],
    this.editedAt,
    this.deletedAt,
  });

  final String id;
  final String conversationId;
  final String? senderId;
  final String senderName;
  final String? senderAvatarPath;
  final String? text;
  final String? mediaUrl;
  final String? mediaType;
  final String? replyToMessageId;
  final ChatMessageReply? replyToMessage;
  final List<String> readBy;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final DateTime at;

  ChatMessage copyWith({List<String>? readBy}) => ChatMessage(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        senderAvatarPath: senderAvatarPath,
        text: text,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        replyToMessageId: replyToMessageId,
        replyToMessage: replyToMessage,
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
        senderAvatarPath: json['senderAvatarPath']?.toString(),
        text: json['text']?.toString(),
        mediaUrl: json['mediaUrl']?.toString(),
        mediaType: json['mediaType']?.toString(),
        replyToMessageId: json['replyToMessageId']?.toString(),
        replyToMessage: json['replyToMessage'] is Map
            ? ChatMessageReply.fromJson(
                Map<String, dynamic>.from(json['replyToMessage'] as Map),
              )
            : null,
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

class ChatMessageReply {
  const ChatMessageReply({
    required this.id,
    required this.senderName,
    this.senderId,
    this.senderAvatarPath,
    this.text,
    this.mediaUrl,
    this.mediaType,
  });

  final String id;
  final String? senderId;
  final String senderName;
  final String? senderAvatarPath;
  final String? text;
  final String? mediaUrl;
  final String? mediaType;

  String get preview {
    final value = text?.trim();
    if (value?.isNotEmpty == true) return value!;
    if (mediaType == 'sticker') return mediaUrl ?? 'Figurinha';
    if (mediaUrl?.isNotEmpty == true) return 'Mídia';
    return 'Mensagem';
  }

  factory ChatMessageReply.fromJson(Map<String, dynamic> json) =>
      ChatMessageReply(
        id: json['id'].toString(),
        senderId: json['senderId']?.toString(),
        senderName: (json['senderName'] ?? 'Visitante').toString(),
        senderAvatarPath: json['senderAvatarPath']?.toString(),
        text: json['text']?.toString(),
        mediaUrl: json['mediaUrl']?.toString(),
        mediaType: json['mediaType']?.toString(),
      );
}

class ChatUser {
  const ChatUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarPath,
  });

  final String id;
  final String? name;
  final String email;
  final String? avatarPath;

  String get label => name?.isNotEmpty == true ? name! : email;

  factory ChatUser.fromJson(Map<String, dynamic> json) => ChatUser(
        id: json['id'].toString(),
        name: json['name']?.toString(),
        email: (json['email'] ?? '').toString(),
        avatarPath: json['avatarPath']?.toString(),
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

const miniGameTypes = ['memory_match', 'love_order', 'this_or_that'];

class MiniGameConfig {
  const MiniGameConfig({
    required this.id,
    required this.type,
    required this.title,
    required this.instructions,
    required this.items,
    this.active = true,
  });

  final String id;
  final String type;
  final String title;
  final String instructions;
  final List<String> items;
  final bool active;

  factory MiniGameConfig.fromJson(Map<String, dynamic> json) => MiniGameConfig(
        id: json['id'].toString(),
        type: (json['type'] ?? '').toString(),
        title: (json['title'] ?? 'Mini jogo').toString(),
        instructions: (json['instructions'] ?? '').toString(),
        items: ((json['items'] as List?) ?? const [])
            .map((item) => item.toString())
            .where((item) => item.trim().isNotEmpty)
            .toList(),
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

class HomeEventConfig {
  const HomeEventConfig({
    required this.title,
    required this.icon,
    required this.date,
    required this.message,
    this.countDirection = HomeCountDirection.forward,
    this.hidden = false,
  });

  final String title;
  final String icon;
  final DateTime date;
  final String message;
  final HomeCountDirection countDirection;
  final bool hidden;

  factory HomeEventConfig.fromJson(Map<String, dynamic> json) =>
      HomeEventConfig(
        title: (json['title'] ?? '').toString(),
        icon: (json['icon'] ?? '').toString(),
        date: DateTime.tryParse(json['date']?.toString() ?? '')?.toLocal() ??
            DateTime.now(),
        message: (json['message'] ?? '').toString(),
        countDirection:
            HomeCountDirection.fromJson(json['countDirection']?.toString()),
        hidden: json['hidden'] == true,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'icon': icon,
        'date': date.toUtc().toIso8601String(),
        'message': message,
        'countDirection': countDirection.value,
        'hidden': hidden,
      };
}

class HomeSettingsConfig {
  const HomeSettingsConfig({
    required this.events,
    this.galleryImages = const [],
    this.galleryOrder,
  });

  final List<HomeEventConfig> events;
  final List<String> galleryImages;
  final int? galleryOrder;

  factory HomeSettingsConfig.fromJson(Map<String, dynamic> json) {
    final events = (json['events'] as List?) ?? const [];
    final galleryImages = (json['galleryImages'] as List?) ?? const [];
    return HomeSettingsConfig(
      events: events
          .map((event) => HomeEventConfig.fromJson(
                Map<String, dynamic>.from(event as Map),
              ))
          .toList(),
      galleryImages: galleryImages
          .map((image) => image.toString())
          .where((image) => image.trim().isNotEmpty)
          .toList(),
      galleryOrder: (json['galleryOrder'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'events': events.map((event) => event.toJson()).toList(),
        'galleryImages': galleryImages,
        if (galleryOrder != null) 'galleryOrder': galleryOrder,
      };
}

enum HomeCountDirection {
  forward('forward'),
  backward('backward');

  const HomeCountDirection(this.value);

  final String value;

  static HomeCountDirection fromJson(String? value) {
    return value == backward.value ? backward : forward;
  }
}
