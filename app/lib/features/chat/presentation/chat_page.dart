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
    text.addListener(_handleTypingChanged);
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
    widget.chat.updateTyping('', senderName: _senderName);
    text.removeListener(_handleTypingChanged);
    text.dispose();
    name.dispose();
    messagesScroll.dispose();
    super.dispose();
  }

  void _handleTypingChanged() {
    widget.chat.updateTyping(text.text, senderName: _senderName);
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
      builder: (sheetContext) => _EmojiStickerSheet(
        onEmoji: (emoji) {
          _insertEmoji(emoji);
          Navigator.of(sheetContext).pop();
        },
        onSticker: (sticker) {
          Navigator.of(sheetContext).pop();
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
      final user = await showAppSheet<ChatUser>(
        context: context,
        builder: (sheetContext) => SizedBox(
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
                  onTap: () => Navigator.of(sheetContext).pop(user),
                ),
            ],
          ),
        ),
      );
      if (user == null || !mounted) return;
      try {
        await widget.chat.createConversation(user);
      } catch (error) {
        widget.toast.error(error.toString());
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
              onReplyMessage: widget.chat.setReply,
              compact: !wide,
              onBack: () => _goBack(context),
              onOpenConversations: _openConversationsSheet,
              showHeader: wide,
            );

            if (!wide) {
              return Container(
                color: palette.bgStart,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                      child: AppPageHeader(
                        title: widget.chat.active?.type == 'global'
                            ? 'Chat'
                            : widget.chat.active?.title ?? 'Chat',
                        subtitle: null,
                        icon: Icons.chat_bubble_outline,
                        leading: _ConversationAvatar(
                          conversation: widget.chat.active,
                          size: 42,
                        ),
                        actionLabel: 'Conversas',
                        actionIcon: Icons.forum_outlined,
                        onAction: _openConversationsSheet,
                        inlineAction: true,
                      ),
                    ),
                    Expanded(child: messages),
                  ],
                ),
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

  Future<void> _openConversationsSheet() async {
    showAppSheet<void>(
      context: context,
      builder: (sheetContext) => SizedBox(
        width: 520,
        height: MediaQuery.of(context).size.height * .72,
        child: _ConversationList(
          chat: widget.chat,
          auth: widget.auth,
          onNewConversation: () {
            Navigator.of(sheetContext).pop();
            _openPeoplePicker();
          },
          onConversationSelected: (conversation) {
            Navigator.of(sheetContext).pop();
            widget.chat
                .loadMessages(conversation)
                .catchError((error) => widget.toast.error(error.toString()));
          },
        ),
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
    this.onConversationSelected,
  });

  final ChatController chat;
  final AuthController auth;
  final VoidCallback onNewConversation;
  final ValueChanged<ChatConversation>? onConversationSelected;

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
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: chat.conversations.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: palette.border),
                  itemBuilder: (context, index) {
                    final conversation = chat.conversations[index];
                    final selected = chat.active?.id == conversation.id;
                    return _ConversationListItem(
                      conversation: conversation,
                      selected: selected,
                      onTap: () {
                        final handler = onConversationSelected;
                        if (handler != null) {
                          handler(conversation);
                          return;
                        }
                        chat
                            .loadMessages(conversation)
                            .catchError((error) => null);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ConversationListItem extends StatelessWidget {
  const _ConversationListItem({
    required this.conversation,
    required this.selected,
    required this.onTap,
  });

  final ChatConversation conversation;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final title = conversation.type == 'global' ? 'Chat' : conversation.title;
    final subtitle = conversation.type == 'global'
        ? 'Todos podem conversar'
        : 'Conversa privada';
    return Material(
      color: selected
          ? palette.primary.withValues(alpha: .08)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 76,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _ConversationAvatar(conversation: conversation, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.foreground,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (conversation.unreadCount > 0) ...[
                  const SizedBox(width: 10),
                  _UnreadBadge(count: conversation.unreadCount),
                ],
              ],
            ),
          ),
        ),
      ),
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
    required this.onReplyMessage,
    required this.compact,
    required this.onBack,
    required this.onOpenConversations,
    this.showHeader = true,
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
  final ValueChanged<ChatMessage> onReplyMessage;
  final bool compact;
  final VoidCallback onBack;
  final VoidCallback onOpenConversations;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final active = chat.active;
    return Column(
      children: [
        if (showHeader) ...[
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
        ],
        if (chat.typingUsers.isNotEmpty)
          _TypingIndicator(names: chat.typingUsers.values.toList()),
        Expanded(
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
                        final previousIndex =
                            chat.messages.length - 1 - index - 1;
                        final previous = previousIndex >= 0
                            ? chat.messages[previousIndex]
                            : null;
                        final showDay = previous == null ||
                            !_isSameDay(previous.at, message.at);
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showDay) _DayDivider(date: message.at),
                            _MessageBubble(
                              message: message,
                              isMine: _isMine(message, auth.user),
                              currentUser: auth.user,
                              compact: compact,
                              onEdit: () => onEditMessage(message),
                              onDelete: () => onDeleteMessage(message),
                              onReply: () => onReplyMessage(message),
                            ),
                          ],
                        );
                      },
                    ),
        ),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (chat.replyingTo != null)
                      _ReplyComposerPreview(
                        message: chat.replyingTo!,
                        onCancel: chat.clearReply,
                      ),
                    Focus(
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
                  ],
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

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final text = count > 99 ? '99+' : count.toString();
    return Container(
      constraints: const BoxConstraints(
        minWidth: 24,
        maxHeight: 24,
        minHeight: 24,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: palette.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final label = names.length == 1
        ? '${names.first} está digitando...'
        : '${names.length} pessoas estão digitando...';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      color: palette.primary.withValues(alpha: .06),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: palette.primary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ReplyComposerPreview extends StatelessWidget {
  const _ReplyComposerPreview({
    required this.message,
    required this.onCancel,
  });

  final ChatMessage message;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: palette.primary, width: 3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ReplyText(
              senderName: message.senderName,
              preview: _messagePreview(message),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onCancel,
            icon: const Icon(Icons.close),
            tooltip: 'Cancelar resposta',
          ),
        ],
      ),
    );
  }
}

class _ReplyPreview extends StatelessWidget {
  const _ReplyPreview({required this.reply});

  final ChatMessageReply reply;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: palette.primary, width: 3)),
      ),
      child: _ReplyText(senderName: reply.senderName, preview: reply.preview),
    );
  }
}

class _ReplyText extends StatelessWidget {
  const _ReplyText({
    required this.senderName,
    required this.preview,
  });

  final String senderName;
  final String preview;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          senderName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: palette.primary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          preview,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: palette.muted, fontSize: 12, height: 1.25),
        ),
      ],
    );
  }
}

String _messagePreview(ChatMessage message) {
  final text = message.text?.trim();
  if (text?.isNotEmpty == true) return text!;
  if (message.mediaType == 'sticker') return message.mediaUrl ?? 'Figurinha';
  if (message.mediaUrl?.isNotEmpty == true) return 'Mídia';
  return 'Mensagem';
}

class _MessageBubble extends StatefulWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.currentUser,
    required this.compact,
    required this.onEdit,
    required this.onDelete,
    required this.onReply,
  });

  final ChatMessage message;
  final bool isMine;
  final AppUser? currentUser;
  final bool compact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReply;

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  static const double _replyDragTrigger = 56;
  static const double _replyDragLimit = 72;

  double _dragOffset = 0;

  void _handleDragUpdate(DragUpdateDetails details) {
    if (widget.message.deletedAt != null) return;
    final next = (_dragOffset + details.delta.dx)
        .clamp(-_replyDragLimit, _replyDragLimit)
        .toDouble();
    if (next == _dragOffset) return;
    setState(() => _dragOffset = next);
  }

  void _handleDragEnd() {
    final shouldReply = _dragOffset.abs() >= _replyDragTrigger;
    setState(() => _dragOffset = 0);
    if (shouldReply) {
      HapticFeedback.selectionClick();
      widget.onReply();
    }
  }

  void _handleDragCancel() {
    if (_dragOffset == 0) return;
    setState(() => _dragOffset = 0);
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final isSticker = widget.message.mediaType == 'sticker';
    final isDeleted = widget.message.deletedAt != null;
    final wasRead =
        widget.message.readBy.any((id) => id != widget.message.senderId);
    final hasText = widget.message.text?.isNotEmpty == true;
    final textOnly =
        hasText && !isDeleted && !isSticker && widget.message.mediaUrl == null;
    final meta = _MessageMeta(
      edited: widget.message.editedAt != null,
      time: _timeLabel(widget.message.at),
      isMine: widget.isMine,
      wasRead: wasRead,
    );
    final canManage = widget.isMine && !isDeleted;
    final replyProgress =
        (_dragOffset.abs() / _replyDragTrigger).clamp(0.0, 1.0).toDouble();
    final replyAlignment =
        _dragOffset < 0 ? Alignment.centerRight : Alignment.centerLeft;
    final bubble = Flexible(
      child: Stack(
        alignment: replyAlignment,
        children: [
          if (!isDeleted)
            Positioned.fill(
              child: Opacity(
                opacity: replyProgress,
                child: Align(
                  alignment: replyAlignment,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: palette.primary.withValues(alpha: .12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.reply,
                      size: 19,
                      color: palette.primary,
                    ),
                  ),
                ),
              ),
            ),
          AnimatedSlide(
            offset: Offset(_dragOffset / 260, 0),
            duration: _dragOffset == 0
                ? const Duration(milliseconds: 170)
                : Duration.zero,
            curve: Curves.easeOutCubic,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: _handleDragUpdate,
              onHorizontalDragEnd: (_) => _handleDragEnd(),
              onHorizontalDragCancel: _handleDragCancel,
              onTap: canManage && textOnly
                  ? () => _openMessageActions(context, canEdit: hasText)
                  : null,
              onDoubleTap: canManage
                  ? () => _openMessageActions(context, canEdit: hasText)
                  : null,
              onLongPress: () => _openMessageActions(context, canEdit: hasText),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isSticker
                      ? Colors.transparent
                      : widget.isMine
                          ? palette.primary.withValues(alpha: .18)
                          : palette.card,
                  border: Border.all(
                    color: isSticker
                        ? Colors.transparent
                        : widget.isMine
                            ? palette.primary.withValues(alpha: .24)
                            : palette.border,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(widget.isMine ? 16 : 5),
                    bottomRight: Radius.circular(widget.isMine ? 5 : 16),
                  ),
                  boxShadow: widget.compact && !isSticker
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: _MessageBubbleContent(
                  message: widget.message,
                  isMine: widget.isMine,
                  compact: widget.compact,
                  isSticker: isSticker,
                  isDeleted: isDeleted,
                  textOnly: textOnly,
                  hasText: hasText,
                  meta: meta,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final avatar = _MessageAvatar(
      name: widget.isMine
          ? (widget.currentUser?.name?.trim().isNotEmpty == true
              ? widget.currentUser!.name!
              : widget.currentUser?.email ?? widget.message.senderName)
          : widget.message.senderName,
      avatarPath: widget.message.senderAvatarPath ??
          (widget.isMine ? widget.currentUser?.avatarPath : null),
      isMine: widget.isMine,
      compact: widget.compact,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: widget.compact ? 8 : 14,
        right: widget.compact ? 8 : 14,
        bottom: widget.compact ? 8 : 10,
      ),
      child: Row(
        mainAxisAlignment:
            widget.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: widget.isMine
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

  Future<void> _openMessageActions(
    BuildContext context, {
    required bool canEdit,
  }) async {
    final action = await showAppSheet<_MessageAction>(
      context: context,
      builder: (sheetContext) => _MessageActionsSheet(
        canEdit: canEdit,
        isMine: widget.isMine,
      ),
    );
    if (action == _MessageAction.reply) {
      widget.onReply();
    } else if (action == _MessageAction.edit) {
      widget.onEdit();
    } else if (action == _MessageAction.delete) {
      widget.onDelete();
    } else if (action == _MessageAction.info && context.mounted) {
      showAppSheet<void>(
        context: context,
        builder: (_) => _MessageInfoSheet(
          message: widget.message,
          isMine: widget.isMine,
          wasRead:
              widget.message.readBy.any((id) => id != widget.message.senderId),
        ),
      );
    }
  }
}

class _MessageBubbleContent extends StatelessWidget {
  const _MessageBubbleContent({
    required this.message,
    required this.isMine,
    required this.compact,
    required this.isSticker,
    required this.isDeleted,
    required this.textOnly,
    required this.hasText,
    required this.meta,
  });

  final ChatMessage message;
  final bool isMine;
  final bool compact;
  final bool isSticker;
  final bool isDeleted;
  final bool textOnly;
  final bool hasText;
  final Widget meta;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return ConstrainedBox(
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
            if (!isDeleted && message.replyToMessage != null) ...[
              SizedBox(height: isMine ? 0 : 5),
              _ReplyPreview(reply: message.replyToMessage!),
              const SizedBox(height: 6),
            ],
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
                style: TextStyle(fontSize: compact ? 72 : 92, height: 1),
              ),
            ] else if (message.mediaUrl != null) ...[
              SizedBox(height: isMine ? 0 : 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () =>
                      _openImagePreview(context, _mediaUrl(message.mediaUrl!)),
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
                        child: Icon(Icons.broken_image_outlined, size: 38),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (textOnly) ...[
              _TextMessageLine(
                text: message.text!,
                compact: compact,
                meta: meta,
              ),
            ] else if (hasText) ...[
              SizedBox(height: message.mediaUrl == null ? 0 : 6),
              Text(
                message.text!,
                style: TextStyle(height: compact ? 1.28 : 1.35),
              ),
            ],
            if (!textOnly && !isSticker) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: meta,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayDivider extends StatelessWidget {
  const _DayDivider({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.card.withValues(alpha: .88),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: palette.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              _dayLabel(date),
              style: TextStyle(
                color: palette.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TextMessageLine extends StatelessWidget {
  const _TextMessageLine({
    required this.text,
    required this.compact,
    required this.meta,
  });

  final String text;
  final bool compact;
  final Widget meta;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 8,
      runSpacing: 2,
      children: [
        Text(
          text,
          style: TextStyle(height: compact ? 1.28 : 1.35),
        ),
        meta,
      ],
    );
  }
}

class _MessageMeta extends StatelessWidget {
  const _MessageMeta({
    required this.edited,
    required this.time,
    required this.isMine,
    required this.wasRead,
  });

  final bool edited;
  final String time;
  final bool isMine;
  final bool wasRead;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (edited) ...[
          Text('editada', style: TextStyle(fontSize: 11, color: palette.muted)),
          const SizedBox(width: 4),
        ],
        Text(time, style: TextStyle(fontSize: 11, color: palette.muted)),
        if (isMine) ...[
          const SizedBox(width: 3),
          Icon(
            wasRead ? Icons.done_all : Icons.done,
            size: 16,
            color: wasRead ? palette.primary : palette.muted,
          ),
        ],
      ],
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

enum _MessageAction { reply, info, edit, delete }

class _MessageActionsSheet extends StatelessWidget {
  const _MessageActionsSheet({required this.canEdit, required this.isMine});

  final bool canEdit;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSheetHeader(
            title: 'Mensagem',
            subtitle: 'Escolha uma ação para esta mensagem.',
            icon: Icons.chat_bubble_outline,
          ),
          const SizedBox(height: 12),
          _MessageActionTile(
            icon: Icons.reply,
            label: 'Responder',
            onTap: () => Navigator.pop(context, _MessageAction.reply),
          ),
          _MessageActionTile(
            icon: Icons.info_outline,
            label: 'Informações',
            onTap: () => Navigator.pop(context, _MessageAction.info),
          ),
          if (isMine && canEdit)
            _MessageActionTile(
              icon: Icons.edit_outlined,
              label: 'Editar',
              onTap: () => Navigator.pop(context, _MessageAction.edit),
            ),
          if (isMine)
            _MessageActionTile(
              icon: Icons.delete_outline,
              label: 'Apagar',
              destructive: true,
              onTap: () => Navigator.pop(context, _MessageAction.delete),
            ),
        ],
      ),
    );
  }
}

class _MessageActionTile extends StatelessWidget {
  const _MessageActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final color = destructive ? Colors.redAccent : palette.foreground;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _MessageInfoSheet extends StatelessWidget {
  const _MessageInfoSheet({
    required this.message,
    required this.isMine,
    required this.wasRead,
  });

  final ChatMessage message;
  final bool isMine;
  final bool wasRead;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 460,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSheetHeader(
            title: 'Informações',
            subtitle: 'Detalhes desta mensagem.',
            icon: Icons.info_outline,
          ),
          const SizedBox(height: 14),
          _MessageInfoRow(
            icon: Icons.person_outline,
            label: 'Enviada por',
            value: message.senderName,
          ),
          _MessageInfoRow(
            icon: Icons.schedule_outlined,
            label: 'Enviada em',
            value: _dateTimeLabel(message.at),
          ),
          if (message.editedAt != null)
            _MessageInfoRow(
              icon: Icons.edit_outlined,
              label: 'Editada em',
              value: _dateTimeLabel(message.editedAt!),
            ),
          if (message.deletedAt != null)
            _MessageInfoRow(
              icon: Icons.delete_outline,
              label: 'Apagada em',
              value: _dateTimeLabel(message.deletedAt!),
            ),
          _MessageInfoRow(
            icon: isMine && wasRead ? Icons.done_all : Icons.done,
            label: 'Status',
            value: isMine ? (wasRead ? 'Visualizada' : 'Enviada') : 'Recebida',
          ),
        ],
      ),
    );
  }
}

class _MessageInfoRow extends StatelessWidget {
  const _MessageInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, color: palette.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: palette.foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
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

String _dateTimeLabel(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();
  return '$day/$month/$year às ${_timeLabel(value)}';
}

String _dayLabel(DateTime value) {
  final now = DateTime.now();
  if (_isSameDay(value, now)) return 'Hoje';
  if (_isSameDay(value, now.subtract(const Duration(days: 1)))) return 'Ontem';
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();
  return '$day/$month/$year';
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
