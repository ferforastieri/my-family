import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/chat/chat_controller.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../data/models.dart';

class ChatFloatingButton extends StatefulWidget {
  const ChatFloatingButton(
      {super.key, required this.chat, required this.auth, required this.toast});

  final ChatController chat;
  final AuthController auth;
  final ToastController toast;

  @override
  State<ChatFloatingButton> createState() => _ChatFloatingButtonState();
}

class _ChatFloatingButtonState extends State<ChatFloatingButton> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Positioned(
      left: 18,
      bottom: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (open)
            _ChatPanel(
              chat: widget.chat,
              auth: widget.auth,
              toast: widget.toast,
              onClose: () => setState(() => open = false),
            ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'global-chat',
            onPressed: () {
              final next = !open;
              setState(() => open = next);
              if (next) widget.chat.refreshConversations();
            },
            backgroundColor: palette.primary,
            foregroundColor: Colors.white,
            icon: Icon(open ? Icons.close : Icons.chat_bubble_outline),
            label: Text(open ? 'Fechar' : 'Chat'),
          ),
        ],
      ),
    );
  }
}

class _ChatPanel extends StatefulWidget {
  const _ChatPanel(
      {required this.chat,
      required this.auth,
      required this.toast,
      required this.onClose});

  final ChatController chat;
  final AuthController auth;
  final ToastController toast;
  final VoidCallback onClose;

  @override
  State<_ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<_ChatPanel> {
  final text = TextEditingController();
  final name = TextEditingController();
  bool sending = false;

  @override
  void dispose() {
    text.dispose();
    name.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    setState(() => sending = true);
    try {
      await widget.chat.sendText(text.text, senderName: name.text);
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
      await widget.chat.sendMedia(text.text, file, senderName: name.text);
      text.clear();
      widget.toast.success('Imagem enviada e salva em Memórias.');
    } catch (error) {
      widget.toast.error(error.toString());
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final size = MediaQuery.of(context).size;
    final panelWidth = size.width < 520 ? size.width - 36 : 420.0;
    final panelHeight = size.height < 700 ? size.height - 120 : 560.0;
    return Material(
      elevation: 18,
      shadowColor: palette.primary.withValues(alpha: .25),
      borderRadius: BorderRadius.circular(18),
      color: palette.card,
      child: Container(
        width: panelWidth,
        height: panelHeight.clamp(420.0, 560.0).toDouble(),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.border),
        ),
        child: ListenableBuilder(
          listenable: widget.chat,
          builder: (context, _) {
            return Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite, color: palette.primary),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(widget.chat.active?.title ?? 'Chat',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 18))),
                    IconButton(
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.close),
                        tooltip: 'Fechar'),
                  ],
                ),
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final conversation in widget.chat.conversations)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            selected: widget.chat.active?.id == conversation.id,
                            label: Text(conversation.type == 'global'
                                ? 'Global'
                                : conversation.title),
                            onSelected: (_) =>
                                widget.chat.loadMessages(conversation),
                          ),
                        ),
                      if (widget.auth.user != null)
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 18),
                          label: const Text('Nova'),
                          onPressed: _openPeoplePicker,
                        ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: widget.chat.loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: widget.chat.messages.length,
                          itemBuilder: (context, index) => _MessageBubble(
                              message: widget.chat.messages[index]),
                        ),
                ),
                if (widget.auth.user == null)
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Seu nome'),
                  ),
                Row(
                  children: [
                    IconButton(
                        onPressed: sending ? null : _sendImage,
                        icon: const Icon(Icons.image_outlined),
                        tooltip: 'Enviar imagem'),
                    Expanded(
                      child: TextField(
                        controller: text,
                        decoration: const InputDecoration(
                            hintText: 'Escreva uma mensagem...'),
                        onSubmitted: (_) => _sendText(),
                      ),
                    ),
                    IconButton(
                        onPressed: sending ? null : _sendText,
                        icon: const Icon(Icons.send),
                        tooltip: 'Enviar'),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openPeoplePicker() async {
    try {
      await widget.chat.refreshUsers();
      if (!mounted) return;
      showAppSheet<void>(
        context: context,
        builder: (context) => SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Nova conversa',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
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
                      widget.chat.createConversation(user);
                    },
                  ),
              ],
            )),
      );
    } catch (error) {
      widget.toast.error(error.toString());
    }
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.primary.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message.senderName,
                  style: TextStyle(
                      color: palette.primary, fontWeight: FontWeight.w900)),
              if (message.mediaUrl != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(_mediaUrl(message.mediaUrl!),
                      height: 140, width: double.infinity, fit: BoxFit.cover),
                ),
              ],
              if (message.text?.isNotEmpty == true) ...[
                const SizedBox(height: 6),
                Text(message.text!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _mediaUrl(String url) {
  if (url.startsWith('http')) return url;
  return AppConfig.apiUri('/fotos/file?path=${Uri.encodeQueryComponent(url)}')
      .toString();
}
