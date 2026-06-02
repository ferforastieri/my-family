import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/family_repository.dart';
import '../../data/models.dart';
import '../socket/socket_client.dart';

class ChatController extends ChangeNotifier {
  ChatController(this.socket, this.repository);

  final SocketClient socket;
  final FamilyRepository repository;

  final List<ChatConversation> conversations = [];
  final List<ChatMessage> messages = [];
  final List<ChatUser> users = [];
  ChatConversation? active;
  bool loading = false;

  Future<void> bootstrap() async {
    socket.on('chat.message.created', (data) {
      if (data is! Map) return;
      final message = ChatMessage.fromJson(Map<String, dynamic>.from(data));
      if (message.conversationId == active?.id) {
        messages.add(message);
        notifyListeners();
      }
    });
    socket.on('chat.conversation.created', (_) => refreshConversations());
    await refreshConversations();
  }

  Future<void> refreshConversations() async {
    final rows = await socket.emitAck<List<dynamic>>('chat.conversations');
    conversations
      ..clear()
      ..addAll(rows.map((row) =>
          ChatConversation.fromJson(Map<String, dynamic>.from(row as Map))));
    active ??= conversations.isNotEmpty ? conversations.first : null;
    if (active != null) await loadMessages(active!);
    notifyListeners();
  }

  Future<void> refreshUsers() async {
    final rows = await socket.emitAck<List<dynamic>>('chat.users');
    users
      ..clear()
      ..addAll(rows.map(
          (row) => ChatUser.fromJson(Map<String, dynamic>.from(row as Map))));
    notifyListeners();
  }

  Future<void> loadMessages(ChatConversation conversation) async {
    active = conversation;
    loading = true;
    notifyListeners();
    try {
      final rows = await socket.emitAck<List<dynamic>>(
          'chat.messages', {'conversationId': conversation.id});
      messages
        ..clear()
        ..addAll(rows.map((row) =>
            ChatMessage.fromJson(Map<String, dynamic>.from(row as Map))));
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> createConversation(ChatUser user) async {
    final row =
        await socket.emitAck<Map<String, dynamic>>('chat.conversation.create', {
      'title': user.label,
      'participantIds': [user.id],
    });
    final conversation = ChatConversation.fromJson(row);
    conversations.add(conversation);
    await loadMessages(conversation);
  }

  Future<void> sendText(String text, {String? senderName}) async {
    final conversation = active;
    if (conversation == null || text.trim().isEmpty) return;
    await socket.emitAck<Map<String, dynamic>>('chat.message.send', {
      'conversationId': conversation.id,
      'text': text.trim(),
      if (senderName != null && senderName.trim().isNotEmpty)
        'senderName': senderName.trim(),
    });
  }

  Future<void> sendMedia(String text, XFile file, {String? senderName}) async {
    final conversation = active;
    if (conversation == null) return;
    final relativePath = await repository.uploadPhotoFile(file);
    final ext = relativePath.split('.').last.toLowerCase();
    final mediaType = ['mp4', 'webm'].contains(ext) ? 'video' : 'image';
    await repository.create('fotos', {
      'url': relativePath,
      'tipo': mediaType == 'video' ? 'video' : 'imagem',
      'texto': text.trim().isEmpty ? 'Imagem enviada no chat' : text.trim(),
      'album': 'Chat',
    });
    await socket.emitAck<Map<String, dynamic>>('chat.message.send', {
      'conversationId': conversation.id,
      'text': text.trim(),
      'mediaUrl': relativePath,
      'mediaType': mediaType,
      if (senderName != null && senderName.trim().isNotEmpty)
        'senderName': senderName.trim(),
    });
  }
}
