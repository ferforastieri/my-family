import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/family_repository.dart';
import '../../data/models.dart';
import '../api/socket_api_client.dart';
import '../socket/socket_client.dart';

class ChatController extends ChangeNotifier {
  ChatController(this.socket, this.repository);

  final SocketClient socket;
  final FamilyRepository repository;
  late final SocketApiClient api = SocketApiClient(socket);

  final List<ChatConversation> conversations = [];
  final List<ChatMessage> messages = [];
  final List<ChatUser> users = [];
  ChatConversation? active;
  bool loading = false;
  bool bootstrapped = false;
  String? errorMessage;

  Future<void> bootstrap() async {
    if (bootstrapped) return;
    bootstrapped = true;
    socket.on('chat.message.created', (data) {
      if (data is! Map) return;
      final message = ChatMessage.fromJson(Map<String, dynamic>.from(data));
      if (message.conversationId == active?.id) {
        if (messages.any((item) => item.id == message.id)) return;
        messages.add(message);
        notifyListeners();
        markRead(message.conversationId);
      }
    });
    socket.on('chat.message.updated', (data) {
      if (data is! Map) return;
      final message = ChatMessage.fromJson(Map<String, dynamic>.from(data));
      final index = messages.indexWhere((item) => item.id == message.id);
      if (index == -1) return;
      messages[index] = message;
      notifyListeners();
    });
    socket.on('chat.messages.read', (data) {
      if (data is! Map) return;
      final receipt = Map<String, dynamic>.from(data);
      final conversationId = receipt['conversationId']?.toString();
      final userId = receipt['userId']?.toString();
      if (conversationId == null || userId == null) return;
      var changed = false;
      for (var index = 0; index < messages.length; index++) {
        final message = messages[index];
        if (message.conversationId != conversationId ||
            message.senderId == userId ||
            message.readBy.contains(userId)) {
          continue;
        }
        messages[index] = message.copyWith(readBy: [...message.readBy, userId]);
        changed = true;
      }
      if (changed) notifyListeners();
    });
    socket.on('chat.conversation.created', (_) => refreshConversations());
    socket.on('connect', (_) {
      if (conversations.isEmpty) {
        refreshConversations(silent: true).catchError((_) {});
      }
    });
    try {
      await refreshConversations(silent: true);
    } catch (_) {
      //
    }
  }

  Future<void> refreshConversations({bool silent = false}) async {
    if (!silent) {
      loading = true;
      errorMessage = null;
      notifyListeners();
    }
    try {
      final data = await api
          .query<dynamic>('chat.conversations', {'page': 1, 'limit': 100});
      final rows = data is List
          ? data
          : ((Map<String, dynamic>.from(data as Map)['items'] as List?) ??
              const []);
      conversations
        ..clear()
        ..addAll(rows.map((row) =>
            ChatConversation.fromJson(Map<String, dynamic>.from(row as Map))));
      active = active == null
          ? (conversations.isNotEmpty ? conversations.first : null)
          : conversations.firstWhere(
              (conversation) => conversation.id == active!.id,
              orElse: () =>
                  conversations.isNotEmpty ? conversations.first : active!,
            );
      if (active != null) await loadMessages(active!);
      errorMessage = null;
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUsers() async {
    final rows = await api.query<List<dynamic>>('chat.users');
    users
      ..clear()
      ..addAll(rows.map(
          (row) => ChatUser.fromJson(Map<String, dynamic>.from(row as Map))));
    notifyListeners();
  }

  Future<void> loadMessages(ChatConversation conversation) async {
    active = conversation;
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final data = await api.query<dynamic>('chat.messages',
          {'conversationId': conversation.id, 'page': 1, 'limit': 80});
      final rows = data is List
          ? data
          : ((Map<String, dynamic>.from(data as Map)['items'] as List?) ??
              const []);
      messages
        ..clear()
        ..addAll(rows.map((row) =>
            ChatMessage.fromJson(Map<String, dynamic>.from(row as Map))));
      await markRead(conversation.id);
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> openConversation(String conversationId) async {
    if (active?.id == conversationId && messages.isNotEmpty) return;
    final conversation =
        conversations.where((item) => item.id == conversationId).firstOrNull;
    if (conversation != null) await loadMessages(conversation);
  }

  Future<void> createConversation(ChatUser user) async {
    final row =
        await api.mutate<Map<String, dynamic>>('chat.conversation.create', {
      'title': user.label,
      'participantIds': [user.id],
    });
    final conversation = ChatConversation.fromJson(row);
    conversations.add(conversation);
    await loadMessages(conversation);
  }

  Future<void> sendText(String text, {String? senderName}) async {
    final conversation = active;
    if (conversation == null) {
      return;
    }
    final row = await api.mutate<Map<String, dynamic>>('chat.message.send', {
      'conversationId': conversation.id,
      'text': text.trim(),
      if (senderName != null && senderName.trim().isNotEmpty)
        'senderName': senderName.trim(),
    });
    final message = ChatMessage.fromJson(row);
    if (!messages.any((item) => item.id == message.id)) {
      messages.add(message);
      notifyListeners();
    }
  }

  Future<void> sendMedia(String text, XFile file, {String? senderName}) async {
    final conversation = active;
    if (conversation == null) {
      return;
    }
    final relativePath = await repository.uploadPhotoFile(file);
    final ext = relativePath.split('.').last.toLowerCase();
    final mediaType = ['mp4', 'webm'].contains(ext) ? 'video' : 'image';
    await repository.create('fotos', {
      'url': relativePath,
      'tipo': mediaType == 'video' ? 'video' : 'imagem',
      'texto': text.trim().isEmpty ? 'Imagem enviada no chat' : text.trim(),
      'album': 'Chat',
    });
    final row = await api.mutate<Map<String, dynamic>>('chat.message.send', {
      'conversationId': conversation.id,
      'text': text.trim(),
      'mediaUrl': relativePath,
      'mediaType': mediaType,
      if (senderName != null && senderName.trim().isNotEmpty)
        'senderName': senderName.trim(),
    });
    final message = ChatMessage.fromJson(row);
    if (!messages.any((item) => item.id == message.id)) {
      messages.add(message);
      notifyListeners();
    }
  }

  Future<void> sendSticker(String sticker, {String? senderName}) async {
    final conversation = active;
    if (conversation == null) return;
    final row = await api.mutate<Map<String, dynamic>>('chat.message.send', {
      'conversationId': conversation.id,
      'mediaUrl': sticker,
      'mediaType': 'sticker',
      if (senderName != null && senderName.trim().isNotEmpty)
        'senderName': senderName.trim(),
    });
    final message = ChatMessage.fromJson(row);
    if (!messages.any((item) => item.id == message.id)) {
      messages.add(message);
      notifyListeners();
    }
  }

  Future<void> markRead(String conversationId) async {
    await api.mutate<Map<String, dynamic>>(
      'chat.messages.read',
      {'conversationId': conversationId},
    );
  }

  Future<void> editMessage(ChatMessage message, String text) async {
    final row = await api.mutate<Map<String, dynamic>>('chat.message.edit', {
      'messageId': message.id,
      'text': text.trim(),
    });
    _replaceMessage(ChatMessage.fromJson(row));
  }

  Future<void> deleteMessage(ChatMessage message) async {
    final row = await api.mutate<Map<String, dynamic>>('chat.message.delete', {
      'messageId': message.id,
    });
    _replaceMessage(ChatMessage.fromJson(row));
  }

  void _replaceMessage(ChatMessage message) {
    final index = messages.indexWhere((item) => item.id == message.id);
    if (index == -1) return;
    messages[index] = message;
    notifyListeners();
  }
}
