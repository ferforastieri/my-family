import 'package:flutter/material.dart';
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
    if (widget.auth.user == null) {
      widget.toast.info('Entre para enviar imagens para Memórias.');
      return;
    }
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => sending = true);
    try {
      await widget.chat.sendMedia(text.text, file, senderName: _senderName);
      text.clear();
      widget.toast.success('Imagem enviada e salva em Memórias.');
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
            );
            final messages = _MessagePane(
              chat: widget.chat,
              auth: widget.auth,
              name: name,
              text: text,
              sending: sending,
              onSendText: _sendText,
              onSendImage: _sendImage,
            );

            return Container(
              color: palette.bgStart,
              padding: EdgeInsets.all(wide ? 18 : 10),
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
                  child: wide
                      ? Row(
                          children: [
                            SizedBox(width: 330, child: sidebar),
                            VerticalDivider(width: 1, color: palette.border),
                            Expanded(child: messages),
                          ],
                        )
                      : Column(
                          children: [
                            SizedBox(height: 142, child: sidebar),
                            Divider(height: 1, color: palette.border),
                            Expanded(child: messages),
                          ],
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ConversationList extends StatelessWidget {
  const _ConversationList({
    required this.chat,
    required this.auth,
    required this.onNewConversation,
  });

  final ChatController chat;
  final AuthController auth;
  final VoidCallback onNewConversation;

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
          child: chat.loading && chat.conversations.isEmpty
              ? const _ConversationSkeleton()
              : ListView.separated(
                  itemCount: chat.conversations.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: palette.border),
                  itemBuilder: (context, index) {
                    final conversation = chat.conversations[index];
                    final selected = chat.active?.id == conversation.id;
                    return ListTile(
                      selected: selected,
                      selectedTileColor: palette.primary.withValues(alpha: .08),
                      leading: CircleAvatar(
                        backgroundColor: palette.primary.withValues(alpha: .16),
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
  });

  final ChatController chat;
  final AuthController auth;
  final TextEditingController name;
  final TextEditingController text;
  final bool sending;
  final VoidCallback onSendText;
  final VoidCallback onSendImage;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final active = chat.active;
    return Column(
      children: [
        Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          color: palette.card,
          child: Row(
            children: [
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
                    Text(
                      active?.type == 'global'
                          ? 'Conversa aberta para todos'
                          : 'Conversa entre pessoas logadas',
                      style: TextStyle(color: palette.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: palette.border),
        Expanded(
          child: active == null
              ? const Center(child: Text('Nenhuma conversa disponível.'))
              : chat.loading
                  ? const _MessagesSkeleton()
                  : ListView.builder(
                      padding: const EdgeInsets.all(18),
                      itemCount: chat.messages.length,
                      itemBuilder: (context, index) {
                        final message = chat.messages[index];
                        return _MessageBubble(
                          message: message,
                          isMine: auth.user != null &&
                              message.senderId == auth.user?.id,
                        );
                      },
                    ),
        ),
        Divider(height: 1, color: palette.border),
        if (auth.user == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Seu nome',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(14),
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
                  ),
                  onSubmitted: (_) => onSendText(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
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
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isMine
                ? palette.primary.withValues(alpha: .18)
                : palette.primary.withValues(alpha: .08),
            border: Border.all(
              color: isMine
                  ? palette.primary.withValues(alpha: .26)
                  : palette.border,
            ),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(isMine ? 14 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 14),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMine)
                    Text(message.senderName,
                        style: TextStyle(
                            color: palette.primary,
                            fontWeight: FontWeight.w900)),
                  if (message.mediaUrl != null) ...[
                    SizedBox(height: isMine ? 0 : 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(_mediaUrl(message.mediaUrl!),
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover),
                    ),
                  ],
                  if (message.text?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Text(message.text!),
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
      ),
    );
  }
}

class _ConversationSkeleton extends StatelessWidget {
  const _ConversationSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
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

String _timeLabel(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
