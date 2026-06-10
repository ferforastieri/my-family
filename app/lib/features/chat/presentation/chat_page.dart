import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/chat/chat_controller.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../data/models.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.chat,
    required this.auth,
    required this.toast,
    this.initialConversationId,
  });

  final ChatController chat;
  final AuthController auth;
  final ToastController toast;
  final String? initialConversationId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final text = TextEditingController();
  final name = TextEditingController();
  final messagesScroll = ScrollController();
  bool sending = false;
  String? _lastScrollSignature;
  String? _lastScrolledConversationId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        await widget.chat.bootstrap();
        await widget.chat.refreshConversations();
        final conversationId = widget.initialConversationId;
        if (conversationId != null) {
          await widget.chat.openConversation(conversationId);
        }
      } catch (error) {
        widget.toast.error(error.toString());
      }
    });
  }

  @override
  void dispose() {
    text.dispose();
    name.dispose();
    messagesScroll.dispose();
    super.dispose();
  }

  void _scheduleScrollToBottom() {
    final chat = widget.chat;
    final conversationId = chat.active?.id;
    if (conversationId == null || chat.loading) return;
    final lastMessageId =
        chat.messages.isEmpty ? 'empty' : chat.messages.last.id;
    final signature = '$conversationId:${chat.messages.length}:$lastMessageId';
    if (_lastScrollSignature == signature) return;

    final animate = _lastScrolledConversationId == conversationId;
    _lastScrollSignature = signature;
    _lastScrolledConversationId = conversationId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !messagesScroll.hasClients) return;
      final end = messagesScroll.position.minScrollExtent;
      if (animate) {
        messagesScroll.animateTo(
          end,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      } else {
        messagesScroll.jumpTo(end);
      }
    });
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

  Future<void> _sendSticker(String sticker) async {
    setState(() => sending = true);
    try {
      await widget.chat.sendSticker(sticker, senderName: _senderName);
    } catch (error) {
      widget.toast.error(error.toString());
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  void _insertEmoji(String emoji) {
    final selection = text.selection;
    final start = selection.isValid ? selection.start : text.text.length;
    final end = selection.isValid ? selection.end : text.text.length;
    final value = text.text.replaceRange(start, end, emoji);
    text.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
  }

  void _openEmojiPanel() {
    showAppSheet<void>(
      context: context,
      builder: (_) => _EmojiStickerSheet(
        onEmoji: _insertEmoji,
        onSticker: (sticker) {
          Navigator.pop(context);
          _sendSticker(sticker);
        },
      ),
    );
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
                  onTap: () async {
                    Navigator.of(context).pop();
                    try {
                      await widget.chat.createConversation(user);
                    } catch (error) {
                      widget.toast.error(error.toString());
                    }
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

  Future<void> _editMessage(ChatMessage message) async {
    final value = await showAppSheet<String>(
      context: context,
      builder: (_) => _EditMessageSheet(initialText: message.text ?? ''),
    );
    if (value == null || !mounted) return;
    try {
      await widget.chat.editMessage(message, value);
      widget.toast.backendSuccess(widget.chat.repository.takeMessage());
    } catch (error) {
      widget.toast.error(error.toString());
    }
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    final confirmed = await showAppSheet<bool>(
      context: context,
      builder: (sheetContext) => SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppSheetHeader(
              title: 'Apagar mensagem?',
              subtitle: 'Ela continuará aparecendo como mensagem apagada.',
              icon: Icons.delete_outline,
            ),
            const SizedBox(height: 20),
            AppSheetActions(
              onCancel: () => Navigator.pop(sheetContext, false),
              onSave: () => Navigator.pop(sheetContext, true),
              saveLabel: 'Apagar',
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.chat.deleteMessage(message);
      widget.toast.backendSuccess(widget.chat.repository.takeMessage());
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
        _scheduleScrollToBottom();
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
              messagesScroll: messagesScroll,
              sending: sending,
              onSendText: _sendText,
              onSendImage: _sendImage,
              onOpenEmojiPanel: _openEmojiPanel,
              onEditMessage: _editMessage,
              onDeleteMessage: _deleteMessage,
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

class _EditMessageSheet extends StatefulWidget {
  const _EditMessageSheet({required this.initialText});

  final String initialText;

  @override
  State<_EditMessageSheet> createState() => _EditMessageSheetState();
}

class _EditMessageSheetState extends State<_EditMessageSheet> {
  late final TextEditingController controller =
      TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = controller.text.trim();
    if (value.isNotEmpty) Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppSheetHeader(
            title: 'Editar mensagem',
            icon: Icons.edit_outlined,
          ),
          const SizedBox(height: 18),
          TextField(
            controller: controller,
            autofocus: true,
            minLines: 2,
            maxLines: 6,
            decoration: const InputDecoration(labelText: 'Mensagem'),
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: 18),
          AppSheetActions(
            onCancel: () => Navigator.pop(context),
            onSave: _save,
          ),
        ],
      ),
    );
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
                        leading: _ConversationAvatar(
                          conversation: conversation,
                          size: 40,
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
    required this.messagesScroll,
    required this.sending,
    required this.onSendText,
    required this.onSendImage,
    required this.onOpenEmojiPanel,
    required this.onEditMessage,
    required this.onDeleteMessage,
    required this.onRefresh,
    required this.compact,
    required this.onBack,
    required this.onOpenConversations,
  });

  final ChatController chat;
  final AuthController auth;
  final TextEditingController name;
  final TextEditingController text;
  final ScrollController messagesScroll;
  final bool sending;
  final VoidCallback onSendText;
  final VoidCallback onSendImage;
  final VoidCallback onOpenEmojiPanel;
  final ValueChanged<ChatMessage> onEditMessage;
  final ValueChanged<ChatMessage> onDeleteMessage;
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
              AppHeaderIconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Voltar',
              ),
              const SizedBox(width: 10),
              _ConversationAvatar(
                conversation: active,
                size: 42,
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
                        controller: messagesScroll,
                        reverse: true,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(18),
                        itemCount: chat.messages.length,
                        itemBuilder: (context, index) {
                          final message =
                              chat.messages[chat.messages.length - 1 - index];
                          return _MessageBubble(
                            message: message,
                            isMine: _isMine(message, auth.user),
                            currentUser: auth.user,
                            compact: compact,
                            onEdit: () => onEditMessage(message),
                            onDelete: () => onDeleteMessage(message),
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
                onPressed: sending ? null : onOpenEmojiPanel,
                icon: const Icon(Icons.sentiment_satisfied_alt_outlined),
                tooltip: 'Emojis e figurinhas',
              ),
              IconButton(
                onPressed: sending ? null : onSendImage,
                icon: const Icon(Icons.image_outlined),
                tooltip: 'Enviar imagem',
              ),
              Expanded(
                child: Focus(
                  onKeyEvent: (_, event) {
                    if (event is! KeyDownEvent ||
                        event.logicalKey != LogicalKeyboardKey.enter) {
                      return KeyEventResult.ignored;
                    }
                    if (HardwareKeyboard.instance.isShiftPressed) {
                      return KeyEventResult.ignored;
                    }
                    if (!sending && text.text.trim().isNotEmpty) {
                      onSendText();
                    }
                    return KeyEventResult.handled;
                  },
                  child: TextField(
                    controller: text,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Escreva uma mensagem...',
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.newline,
                  ),
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
    required this.onEdit,
    required this.onDelete,
  });

  final ChatMessage message;
  final bool isMine;
  final AppUser? currentUser;
  final bool compact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final isSticker = message.mediaType == 'sticker';
    final isDeleted = message.deletedAt != null;
    final wasRead = message.readBy.any((id) => id != message.senderId);
    final bubble = Flexible(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isSticker
              ? Colors.transparent
              : isMine
                  ? palette.primary.withValues(alpha: .18)
                  : palette.card,
          border: Border.all(
            color: isSticker
                ? Colors.transparent
                : isMine
                    ? palette.primary.withValues(alpha: .24)
                    : palette.border,
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 5),
            bottomRight: Radius.circular(isMine ? 5 : 16),
          ),
          boxShadow: compact && !isSticker
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
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 10 : 12,
                  compact ? 8 : 12,
                  isMine && !isDeleted ? 34 : (compact ? 10 : 12),
                  compact ? 7 : 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMine)
                      Text(
                        message.senderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    if (isDeleted)
                      Text(
                        'Mensagem apagada',
                        style: TextStyle(
                          color: palette.muted,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else if (isSticker && message.mediaUrl != null) ...[
                      SizedBox(height: isMine ? 0 : 4),
                      Text(
                        message.mediaUrl!,
                        style:
                            TextStyle(fontSize: compact ? 72 : 92, height: 1),
                      ),
                    ] else if (message.mediaUrl != null) ...[
                      SizedBox(height: isMine ? 0 : 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () => _openImagePreview(
                              context, _mediaUrl(message.mediaUrl!)),
                          child: Image.network(
                            _mediaUrl(message.mediaUrl!),
                            height: compact ? 180 : 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return SizedBox(
                                height: compact ? 180 : 220,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => SizedBox(
                              height: compact ? 120 : 150,
                              child: const Center(
                                child:
                                    Icon(Icons.broken_image_outlined, size: 38),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (message.text?.isNotEmpty == true) ...[
                      SizedBox(height: message.mediaUrl == null ? 0 : 6),
                      Text(message.text!,
                          style: TextStyle(height: compact ? 1.28 : 1.35)),
                    ],
                    if (!isSticker) const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (message.editedAt != null) ...[
                            Text(
                              'editada',
                              style:
                                  TextStyle(fontSize: 11, color: palette.muted),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            _timeLabel(message.at),
                            style:
                                TextStyle(fontSize: 11, color: palette.muted),
                          ),
                          if (isMine) ...[
                            const SizedBox(width: 3),
                            Icon(
                              wasRead ? Icons.done_all : Icons.done,
                              size: 16,
                              color: wasRead ? palette.primary : palette.muted,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isMine && !isDeleted)
                Positioned(
                  top: 1,
                  right: 1,
                  child: PopupMenuButton<_MessageAction>(
                    tooltip: 'Opções da mensagem',
                    position: PopupMenuPosition.under,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 132,
                      maxWidth: 180,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: palette.border),
                    ),
                    color: palette.card,
                    elevation: 6,
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 17,
                        color: palette.muted,
                      ),
                    ),
                    onSelected: (action) {
                      if (action == _MessageAction.edit) {
                        onEdit();
                      } else {
                        onDelete();
                      }
                    },
                    itemBuilder: (_) => [
                      if (message.text?.isNotEmpty == true)
                        const PopupMenuItem(
                          value: _MessageAction.edit,
                          height: 40,
                          child: _MessageMenuItem(
                            icon: Icons.edit_outlined,
                            label: 'Editar',
                          ),
                        ),
                      const PopupMenuItem(
                        value: _MessageAction.delete,
                        height: 40,
                        child: _MessageMenuItem(
                          icon: Icons.delete_outline,
                          label: 'Apagar',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
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

class _EmojiStickerSheet extends StatelessWidget {
  const _EmojiStickerSheet({
    required this.onEmoji,
    required this.onSticker,
  });

  final ValueChanged<String> onEmoji;
  final ValueChanged<String> onSticker;

  static const emojis = [
    '😀',
    '😂',
    '🥰',
    '😍',
    '😊',
    '😉',
    '🥹',
    '😘',
    '😋',
    '😎',
    '🤩',
    '🥳',
    '😭',
    '😡',
    '🤔',
    '🫶',
    '👍',
    '👏',
    '🙏',
    '💪',
    '❤️',
    '💕',
    '💖',
    '💘',
    '🌸',
    '🌹',
    '✨',
    '🎉',
    '🔥',
    '⭐',
    '☀️',
    '🌙',
  ];

  static const stickers = [
    '🥰',
    '😂',
    '😭',
    '😡',
    '🥳',
    '🤩',
    '🫶',
    '❤️',
    '💐',
    '🌹',
    '🎉',
    '🔥',
  ];

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return SizedBox(
      width: 520,
      child: DefaultTabController(
        length: 2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppSheetHeader(
              title: 'Emojis e figurinhas',
              subtitle: 'Escolha um emoji ou envie uma figurinha.',
              icon: Icons.sentiment_satisfied_alt_outlined,
            ),
            const SizedBox(height: 12),
            TabBar(
              tabs: const [
                Tab(icon: Icon(Icons.emoji_emotions_outlined), text: 'Emojis'),
                Tab(
                    icon: Icon(Icons.sticky_note_2_outlined),
                    text: 'Figurinhas'),
              ],
              labelColor: palette.primary,
              indicatorColor: palette.primary,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 280,
              child: TabBarView(
                children: [
                  GridView.builder(
                    padding: const EdgeInsets.all(4),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                    ),
                    itemCount: emojis.length,
                    itemBuilder: (_, index) => _EmojiButton(
                      emoji: emojis[index],
                      onTap: () => onEmoji(emojis[index]),
                    ),
                  ),
                  GridView.builder(
                    padding: const EdgeInsets.all(6),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: stickers.length,
                    itemBuilder: (_, index) => _StickerButton(
                      sticker: stickers[index],
                      onTap: () => onSticker(stickers[index]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiButton extends StatelessWidget {
  const _EmojiButton({required this.emoji, required this.onTap});

  final String emoji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 27)),
      ),
    );
  }
}

class _StickerButton extends StatelessWidget {
  const _StickerButton({required this.sticker, required this.onTap});

  final String sticker;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.primary.withValues(alpha: .07),
          border: Border.all(color: palette.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(sticker, style: const TextStyle(fontSize: 52)),
        ),
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

class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({
    required this.conversation,
    required this.size,
  });

  final ChatConversation? conversation;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final isGlobal = conversation?.type == 'global';
    final title = isGlobal ? 'Família' : conversation?.title ?? 'Pessoa';
    final initial = _initialFor(title);
    final avatarPath = conversation?.avatarPath;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: .12),
        shape: BoxShape.circle,
        border: Border.all(color: palette.primary.withValues(alpha: .22)),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: isGlobal
          ? Image.asset(
              'assets/brand/family-logo.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _AvatarInitial(
                initial: initial,
                color: palette.primary,
              ),
            )
          : avatarPath?.isNotEmpty == true
              ? Image.network(
                  _avatarUrl(avatarPath!),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _AvatarInitial(
                    initial: initial,
                    color: palette.primary,
                  ),
                )
              : _AvatarInitial(
                  initial: initial,
                  color: palette.primary,
                ),
    );
  }
}

class _AvatarInitial extends StatelessWidget {
  const _AvatarInitial({required this.initial, required this.color});

  final String initial;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      initial,
      style: TextStyle(
        color: color,
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

enum _MessageAction { edit, delete }

class _MessageMenuItem extends StatelessWidget {
  const _MessageMenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 19),
        const SizedBox(width: 10),
        Text(label),
      ],
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
  showAppSheet<void>(
    context: context,
    builder: (sheetContext) => SizedBox(
      width: 900,
      height: MediaQuery.sizeOf(sheetContext).height * .72,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ColoredBox(
          color: Colors.black,
          child: InteractiveViewer(
            minScale: .8,
            maxScale: 4,
            child: Center(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (_, __, ___) => const Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white,
                      size: 54,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Não foi possível carregar a imagem.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
