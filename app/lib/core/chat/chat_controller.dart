import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/family_repository.dart';
import '../../data/models.dart';
import '../api/http_api_client.dart';
import '../socket/socket_client.dart';

class ChatController extends ChangeNotifier {
  ChatController(this.socket, this.repository);

  final SocketClient socket;
  final FamilyRepository repository;
  late final HttpApiClient api = HttpApiClient(socket);

  final List<ChatConversation> conversations = [];
  final List<ChatMessage> messages = [];
  final List<ChatUser> users = [];
  final Map<String, String> typingUsers = {};
  ChatConversation? active;
  bool loading = false;
  bool bootstrapped = false;
  bool _listenersBound = false;
  String? errorMessage;
  Timer? _typingStopTimer;
  Timer? _remoteTypingClearTimer;
  bool _localTypingSent = false;
  DateTime? _lastTypingSentAt;
  ChatMessage? replyingTo;

  int get unreadCount => conversations.fold(
    0,
    (total, conversation) => total + conversation.unreadCount,
  );

  Future<void> bootstrap() async {
    if (!_listenersBound) {
      _listenersBound = true;
      socket.on('chat.message.created', (data) {
        if (data is! Map) return;
        final message = ChatMessage.fromJson(Map<String, dynamic>.from(data));
        if (message.conversationId == active?.id) {
          if (messages.any((item) => item.id == message.id)) return;
          messages.add(message);
          notifyListeners();
          markRead(message.conversationId);
        } else {
          _refreshUnreadCounters();
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
          messages[index] = message.copyWith(
            readBy: [...message.readBy, userId],
          );
          changed = true;
        }
        if (changed) notifyListeners();
        _markConversationRead(conversationId);
      });
      socket.on('chat.typing', (data) {
        if (data is! Map) return;
        final payload = Map<String, dynamic>.from(data);
        final conversationId = payload['conversationId']?.toString();
        final userId = payload['userId']?.toString();
        final senderName = payload['senderName']?.toString();
        final isTyping = payload['isTyping'] == true;
        if (conversationId != active?.id ||
            userId == null ||
            senderName == null) {
          return;
        }
        if (isTyping) {
          typingUsers[userId] = senderName;
          _remoteTypingClearTimer?.cancel();
          _remoteTypingClearTimer = Timer(
            const Duration(seconds: 4),
            clearTypingUsers,
          );
        } else {
          typingUsers.remove(userId);
        }
        notifyListeners();
      });
      socket.on('chat.conversation.created', (_) => _refreshUnreadCounters());
      socket.on('connect', (_) {
        if (conversations.isEmpty) {
          refreshConversations(silent: true).catchError((_) {});
        }
      });
    }
    if (bootstrapped && conversations.isNotEmpty) return;
    try {
      await refreshConversations(silent: true);
      bootstrapped = true;
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
      final data = await api.query<dynamic>('chat.conversations', {
        'page': 1,
        'limit': 100,
      });
      final rows = data is List
          ? data
          : ((Map<String, dynamic>.from(data as Map)['items'] as List?) ??
                const []);
      conversations
        ..clear()
        ..addAll(
          rows.map(
            (row) => ChatConversation.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          ),
        );
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
      ..addAll(
        rows.map(
          (row) => ChatUser.fromJson(Map<String, dynamic>.from(row as Map)),
        ),
      );
    notifyListeners();
  }

  Future<void> loadMessages(ChatConversation conversation) async {
    active = conversation;
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final data = await api.query<dynamic>('chat.messages', {
        'conversationId': conversation.id,
        'page': 1,
        'limit': 80,
      });
      final rows = data is List
          ? data
          : ((Map<String, dynamic>.from(data as Map)['items'] as List?) ??
                const []);
      messages
        ..clear()
        ..addAll(
          rows.map(
            (row) =>
                ChatMessage.fromJson(Map<String, dynamic>.from(row as Map)),
          ),
        );
      clearReply();
      clearTypingUsers();
      await markRead(conversation.id);
      _markConversationRead(conversation.id);
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
    final conversation = conversations
        .where((item) => item.id == conversationId)
        .firstOrNull;
    if (conversation != null) await loadMessages(conversation);
  }

  Future<void> createConversation(ChatUser user) async {
    final row = await api.mutate<Map<String, dynamic>>(
      'chat.conversation.create',
      {
        'title': user.label,
        'participantIds': [user.id],
      },
    );
    final conversation = ChatConversation.fromJson(row);
    conversations.add(conversation);
    await loadMessages(conversation);
  }

  Future<void> sendText(String text, {String? senderName}) async {
    final conversation = active;
    if (conversation == null) {
      return;
    }
    final reply = replyingTo;
    final row = await api.mutate<Map<String, dynamic>>('chat.message.send', {
      'conversationId': conversation.id,
      'text': text.trim(),
      if (reply != null) 'replyToMessageId': reply.id,
      if (senderName != null && senderName.trim().isNotEmpty)
        'senderName': senderName.trim(),
    });
    clearReply();
    await sendTyping(false, senderName: senderName);
    final message = ChatMessage.fromJson(row);
    if (!messages.any((item) => item.id == message.id)) {
      messages.add(message);
      _markConversationRead(message.conversationId);
      notifyListeners();
    }
  }

  Future<void> sendMedia(String text, XFile file, {String? senderName}) async {
    final conversation = active;
    if (conversation == null) {
      return;
    }
    final reply = replyingTo;
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
      if (reply != null) 'replyToMessageId': reply.id,
      if (senderName != null && senderName.trim().isNotEmpty)
        'senderName': senderName.trim(),
    });
    clearReply();
    await sendTyping(false, senderName: senderName);
    final message = ChatMessage.fromJson(row);
    if (!messages.any((item) => item.id == message.id)) {
      messages.add(message);
      _markConversationRead(message.conversationId);
      notifyListeners();
    }
  }

  Future<void> sendSticker(String sticker, {String? senderName}) async {
    final conversation = active;
    if (conversation == null) return;
    final reply = replyingTo;
    final row = await api.mutate<Map<String, dynamic>>('chat.message.send', {
      'conversationId': conversation.id,
      'mediaUrl': sticker,
      'mediaType': 'sticker',
      if (reply != null) 'replyToMessageId': reply.id,
      if (senderName != null && senderName.trim().isNotEmpty)
        'senderName': senderName.trim(),
    });
    clearReply();
    await sendTyping(false, senderName: senderName);
    final message = ChatMessage.fromJson(row);
    if (!messages.any((item) => item.id == message.id)) {
      messages.add(message);
      _markConversationRead(message.conversationId);
      notifyListeners();
    }
  }

  Future<void> markRead(String conversationId) async {
    await api.mutate<Map<String, dynamic>>('chat.messages.read', {
      'conversationId': conversationId,
    });
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

  void setReply(ChatMessage message) {
    if (message.deletedAt != null) return;
    replyingTo = message;
    notifyListeners();
  }

  void clearReply() {
    if (replyingTo == null) return;
    replyingTo = null;
    notifyListeners();
  }

  void updateTyping(String value, {String? senderName}) {
    final isTyping = value.trim().isNotEmpty;
    final now = DateTime.now();
    if (isTyping &&
        (!_localTypingSent ||
            _lastTypingSentAt == null ||
            now.difference(_lastTypingSentAt!) > const Duration(seconds: 2))) {
      unawaited(sendTyping(true, senderName: senderName));
    }
    _typingStopTimer?.cancel();
    if (isTyping) {
      _typingStopTimer = Timer(
        const Duration(milliseconds: 1400),
        () => unawaited(sendTyping(false, senderName: senderName)),
      );
    } else {
      unawaited(sendTyping(false, senderName: senderName));
    }
  }

  Future<void> sendTyping(bool isTyping, {String? senderName}) async {
    final conversation = active;
    if (conversation == null) return;
    if (_localTypingSent == isTyping &&
        isTyping &&
        _lastTypingSentAt != null &&
        DateTime.now().difference(_lastTypingSentAt!) <
            const Duration(seconds: 2)) {
      return;
    }
    _localTypingSent = isTyping;
    _lastTypingSentAt = DateTime.now();
    try {
      await api.mutate<Map<String, dynamic>>('chat.typing', {
        'conversationId': conversation.id,
        'isTyping': isTyping,
        if (senderName != null && senderName.trim().isNotEmpty)
          'senderName': senderName.trim(),
      });
    } catch (_) {
      //
    }
  }

  void clearTypingUsers() {
    if (typingUsers.isEmpty) return;
    typingUsers.clear();
    notifyListeners();
  }

  void _markConversationRead(String conversationId) {
    final index = conversations.indexWhere(
      (conversation) => conversation.id == conversationId,
    );
    if (index == -1 || conversations[index].unreadCount == 0) return;
    conversations[index] = conversations[index].copyWith(unreadCount: 0);
    notifyListeners();
  }

  void _refreshUnreadCounters() {
    refreshConversations(silent: true).catchError((_) {});
  }
}
