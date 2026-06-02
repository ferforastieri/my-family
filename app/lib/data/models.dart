class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.name,
    this.avatarPath,
  });

  final String id;
  final String email;
  final String role;
  final String? name;
  final String? avatarPath;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'].toString(),
        email: json['email'] as String,
        role: (json['role'] ?? 'friend') as String,
        name: json['name'] as String?,
        avatarPath: json['avatarPath'] as String?,
      );
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
  });

  final String id;
  final String conversationId;
  final String? senderId;
  final String senderName;
  final String? text;
  final String? mediaUrl;
  final String? mediaType;
  final DateTime at;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'].toString(),
        conversationId: json['conversationId'].toString(),
        senderId: json['senderId']?.toString(),
        senderName: (json['senderName'] ?? 'Visitante').toString(),
        text: json['text']?.toString(),
        mediaUrl: json['mediaUrl']?.toString(),
        mediaType: json['mediaType']?.toString(),
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
