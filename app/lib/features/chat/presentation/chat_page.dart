import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/chat/chat_controller.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../data/models.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.chat,
    required this.auth,
    required this.toast,
  });

  final ChatController chat;
  final AuthController auth;
  final ToastController toast;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final text = TextEditingController();
  final name = TextEditingController();
  bool sending = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        await widget.chat.bootstrap();
        await widget.chat.refreshConversations();
      } catch (error) {
        widget.toast.error(error.toString());
      }
    });
  }

  @override
  void dispose() {
    text.dispose();
    name.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    setState(() => sending = true);
    try {
      await widget.chat.sendText(text.text, senderName: _senderName);
      text.clear();
    } catch (error) {
      widget.toast.error(error.toString());
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => sending = true);
    try {
      await widget.chat.sendMedia(text.text, file, senderName: _senderName);
      text.clear();
      widget.toast.backendSuccess(widget.chat.repository.takeMessage());
    } catch (error) {
      widget.toast.error(error.toString());
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  String get _senderName {
    final user = widget.auth.user;
    if (user != null) {
      final displayName = user.name?.trim();
      return displayName?.isNotEmpty == true ? displayName! : user.email;
    }
    return name.text.trim();
  }

  Future<void> _openPeoplePicker() async {
    try {
      await widget.chat.refreshUsers();
      if (!mounted) return;
      showAppSheet<void>(
        context: context,
        builder: (context) => SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Nova conversa',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              if (widget.chat.users.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Nenhuma pessoa encontrada.'),
                ),
              for (final user in widget.chat.users)
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(user.label),
                  onTap: () {
                    Navigator.pop(context);
                    widget.chat.createConversation(user).catchError(
                        (error) => widget.toast.error(error.toString()));
                  },
                ),
            ],
          ),
        ),
      );
    } catch (error) {
      widget.toast.error(error.toString());
    }
  }

  Future<void> _refreshChat() async {
    try {
      await widget.chat.refreshConversations();
    } catch (error) {
      widget.toast.error(error.toString());
    }
  }

  Future<void> _refreshMessages() async {
    try {
      final active = widget.chat.active;
      if (active == null) {
        await widget.chat.refreshConversations();
      } else {
        await widget.chat.loadMessages(active);
      }
    } catch (error) {
      widget.toast.error(error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return ListenableBuilder(
      listenable: widget.chat,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 820;
            final sidebar = _ConversationList(
              chat: widget.chat,
              auth: widget.auth,
              onNewConversation: _openPeoplePicker,
              onRefresh: _refreshChat,
            );
            final messages = _MessagePane(
              chat: widget.chat,
              auth: widget.auth,
              name: name,
              text: text,
              sending: sending,
              onSendText: _sendText,
              onSendImage: _sendImage,
              onRefresh: _refreshMessages,
              compact: !wide,
              onBack: () => _goBack(context),
              onOpenConversations: () => _openConversationsSheet(sidebar),
            );

            if (!wide) {
              return Container(
                color: palette.bgStart,
                child: messages,
              );
            }

            return Container(
              color: palette.bgStart,
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 112),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: palette.card,
                      border: Border.all(color: palette.border),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: palette.primary.withValues(alpha: .08),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          SizedBox(width: 330, child: sidebar),
                          VerticalDivider(width: 1, color: palette.border),
                          Expanded(child: messages),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openConversationsSheet(Widget sidebar) {
    showAppSheet<void>(
      context: context,
      builder: (_) => SizedBox(
        width: 520,
        height: MediaQuery.of(context).size.height * .72,
        child: sidebar,
      ),
    );
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }
}

class _ConversationList extends StatelessWidget {
  const _ConversationList({
    required this.chat,
    required this.auth,
    required this.onNewConversation,
    required this.onRefresh,
  });

  final ChatController chat;
  final AuthController auth;
  final VoidCallback onNewConversation;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Column(
      children: [
        Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: palette.primary.withValues(alpha: .08),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: palette.primary,
                foregroundColor: Colors.white,
                child: const Icon(Icons.chat_bubble_outline),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Conversas',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ),
              if (auth.user != null)
                IconButton(
                  onPressed: onNewConversation,
                  icon: const Icon(Icons.add_comment_outlined),
                  tooltip: 'Nova conversa',
                ),
            ],
          ),
        ),
        if (chat.errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(chat.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: chat.loading && chat.conversations.isEmpty
                ? const _ConversationSkeleton()
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: chat.conversations.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: palette.border),
                    itemBuilder: (context, index) {
                      final conversation = chat.conversations[index];
                      final selected = chat.active?.id == conversation.id;
                      return ListTile(
                        selected: selected,
                        selectedTileColor:
                            palette.primary.withValues(alpha: .08),
                        leading: CircleAvatar(
                          backgroundColor:
                              palette.primary.withValues(alpha: .16),
                          foregroundColor: palette.primary,
                          child: Icon(conversation.type == 'global'
                              ? Icons.public
                              : Icons.person_outline),
                        ),
                        title: Text(conversation.type == 'global'
                            ? 'Chat'
                            : conversation.title),
                        subtitle: Text(conversation.type == 'global'
                            ? 'Todos podem conversar'
                            : 'Conversa privada'),
                        onTap: () => chat
                            .loadMessages(conversation)
                            .catchError((error) => null),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _MessagePane extends StatelessWidget {
  const _MessagePane({
    required this.chat,
    required this.auth,
    required this.name,
    required this.text,
    required this.sending,
    required this.onSendText,
    required this.onSendImage,
    required this.onRefresh,
    required this.compact,
    required this.onBack,
    required this.onOpenConversations,
  });

  final ChatController chat;
  final AuthController auth;
  final TextEditingController name;
  final TextEditingController text;
  final bool sending;
  final VoidCallback onSendText;
  final VoidCallback onSendImage;
  final Future<void> Function() onRefresh;
  final bool compact;
  final VoidCallback onBack;
  final VoidCallback onOpenConversations;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final active = chat.active;
    return Column(
      children: [
        Container(
          height: compact ? 64 : 72,
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 18),
          color:
              compact ? palette.primary.withValues(alpha: .08) : palette.card,
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Voltar',
              ),
              const SizedBox(width: 2),
              CircleAvatar(
                backgroundColor: palette.primary.withValues(alpha: .16),
                foregroundColor: palette.primary,
                child: Icon(active?.type == 'global'
                    ? Icons.public
                    : Icons.favorite_outline),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        active?.type == 'global'
                            ? 'Chat'
                            : active?.title ?? 'Chat',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900)),
                    if (!compact)
                      Text(
                        active?.type == 'global'
                            ? 'Conversa aberta para todos'
                            : 'Conversa entre pessoas logadas',
                        style: TextStyle(color: palette.muted),
                      ),
                  ],
                ),
              ),
              if (compact)
                IconButton(
                  onPressed: onOpenConversations,
                  icon: const Icon(Icons.forum_outlined),
                  tooltip: 'Conversas',
                ),
            ],
          ),
        ),
        Divider(height: 1, color: palette.border),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: active == null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 180),
                      Center(child: Text('Nenhuma conversa disponível.')),
                    ],
                  )
                : chat.loading
                    ? const _MessagesSkeleton()
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(18),
                        itemCount: chat.messages.length,
                        itemBuilder: (context, index) {
                          final message = chat.messages[index];
                          return _MessageBubble(
                            message: message,
                            isMine: _isMine(message, auth.user),
                            currentUser: auth.user,
                            compact: compact,
                          );
                        },
                      ),
          ),
        ),
        Divider(height: 1, color: palette.border),
        if (auth.user == null)
          Padding(
            padding:
                EdgeInsets.fromLTRB(compact ? 10 : 14, 8, compact ? 10 : 14, 0),
            child: TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Seu nome',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSendText(),
            ),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 8 : 14,
            8,
            compact ? 8 : 14,
            compact ? 10 : 14,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: sending ? null : onSendImage,
                icon: const Icon(Icons.image_outlined),
                tooltip: 'Enviar imagem',
              ),
              Expanded(
                child: TextField(
                  controller: text,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Escreva uma mensagem...',
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSendText(),
                ),
              ),
              SizedBox(width: compact ? 6 : 8),
              FilledButton(
                style: compact
                    ? FilledButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(14),
                        minimumSize: const Size(48, 48),
                      )
                    : null,
                onPressed: sending ? null : onSendText,
                child: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.currentUser,
    required this.compact,
  });

  final ChatMessage message;
  final bool isMine;
  final AppUser? currentUser;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final bubble = Flexible(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isMine ? palette.primary.withValues(alpha: .18) : palette.card,
          border: Border.all(
            color: isMine
                ? palette.primary.withValues(alpha: .24)
                : palette.border,
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 5),
            bottomRight: Radius.circular(isMine ? 5 : 16),
          ),
          boxShadow: compact
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: compact ? 280 : 560),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 10 : 12,
              compact ? 8 : 12,
              compact ? 10 : 12,
              compact ? 7 : 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMine)
                  Text(message.senderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: palette.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900)),
                if (message.mediaUrl != null) ...[
                  SizedBox(height: isMine ? 0 : 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => _openImagePreview(
                          context, _mediaUrl(message.mediaUrl!)),
                      child: Image.network(_mediaUrl(message.mediaUrl!),
                          height: compact ? 180 : 220,
                          width: double.infinity,
                          fit: BoxFit.cover),
                    ),
                  ),
                ],
                if (message.text?.isNotEmpty == true) ...[
                  SizedBox(height: message.mediaUrl == null ? 0 : 6),
                  Text(message.text!,
                      style: TextStyle(height: compact ? 1.28 : 1.35)),
                ],
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _timeLabel(message.at),
                    style: TextStyle(fontSize: 11, color: palette.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final avatar = _MessageAvatar(
      name: isMine
          ? (currentUser?.name?.trim().isNotEmpty == true
              ? currentUser!.name!
              : currentUser?.email ?? message.senderName)
          : message.senderName,
      avatarPath: isMine ? currentUser?.avatarPath : null,
      isMine: isMine,
      compact: compact,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: compact ? 8 : 14,
        right: compact ? 8 : 14,
        bottom: compact ? 8 : 10,
      ),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: isMine
            ? [
                const Spacer(),
                bubble,
                const SizedBox(width: 7),
                avatar,
              ]
            : [
                avatar,
                const SizedBox(width: 7),
                bubble,
                const Spacer(),
              ],
      ),
    );
  }
}

class _MessageAvatar extends StatelessWidget {
  const _MessageAvatar({
    required this.name,
    required this.avatarPath,
    required this.isMine,
    required this.compact,
  });

  final String name;
  final String? avatarPath;
  final bool isMine;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final size = compact ? 30.0 : 34.0;
    final initial = _initialFor(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isMine
            ? palette.primary.withValues(alpha: .18)
            : palette.primaryDark.withValues(alpha: .13),
        shape: BoxShape.circle,
        border: Border.all(color: palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: avatarPath?.isNotEmpty == true
          ? Image.network(
              _avatarUrl(avatarPath!),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Text(
                initial,
                style: TextStyle(
                  color: palette.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 12 : 13,
                ),
              ),
            )
          : Text(
              initial,
              style: TextStyle(
                color: palette.primary,
                fontWeight: FontWeight.w900,
                fontSize: compact ? 12 : 13,
              ),
            ),
    );
  }
}

String _initialFor(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.characters.first.toUpperCase();
}

bool _isMine(ChatMessage message, AppUser? user) {
  if (user == null) return false;
  if (message.senderId == user.id) return true;
  final displayName = user.name?.trim();
  final expected = displayName?.isNotEmpty == true ? displayName! : user.email;
  return message.senderId == null && message.senderName == expected;
}

class _ConversationSkeleton extends StatelessWidget {
  const _ConversationSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const Row(
        children: [
          SkeletonBox(width: 44, height: 44, borderRadius: 999),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 160, height: 16),
                SizedBox(height: 8),
                SkeletonBox(width: 110, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessagesSkeleton extends StatelessWidget {
  const _MessagesSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(18),
      children: const [
        Align(
          alignment: Alignment.centerLeft,
          child: SkeletonBox(width: 260, height: 70, borderRadius: 14),
        ),
        SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: SkeletonBox(width: 310, height: 78, borderRadius: 14),
        ),
        SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: SkeletonBox(width: 220, height: 64, borderRadius: 14),
        ),
      ],
    );
  }
}

String _mediaUrl(String url) {
  if (url.startsWith('http')) return url;
  return AppConfig.apiUri('/fotos/file?path=${Uri.encodeQueryComponent(url)}')
      .toString();
}

void _openImagePreview(BuildContext context, String url) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .92),
    builder: (context) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: .8,
              maxScale: 4,
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton.filledTonal(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                tooltip: 'Fechar',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

String _avatarUrl(String path) {
  return AppConfig.apiUri('/auth/avatar?path=${Uri.encodeQueryComponent(path)}')
      .toString();
}

String _timeLabel(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
