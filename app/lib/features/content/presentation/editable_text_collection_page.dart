import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/love_action_card.dart';
import '../../../core/widgets/love_background.dart';
import '../../../core/widgets/love_text_card.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../data/family_repository.dart';
import '../../../data/models.dart';

class EditableTextCollectionPage extends StatefulWidget {
  const EditableTextCollectionPage({
    super.key,
    required this.title,
    required this.prefix,
    required this.repository,
    required this.toast,
    required this.auth,
  });

  final String title;
  final String prefix;
  final FamilyRepository repository;
  final ToastController toast;
  final AuthController auth;

  @override
  State<EditableTextCollectionPage> createState() =>
      _EditableTextCollectionPageState();
}

class _EditableTextCollectionPageState
    extends State<EditableTextCollectionPage> {
  late Future<List<FamilyItem>> future = _load();

  @override
  void initState() {
    super.initState();
    for (final event in _events) {
      widget.repository.socket.on(event, _handleRealtimeChange);
    }
  }

  @override
  void dispose() {
    for (final event in _events) {
      widget.repository.socket.off(event, _handleRealtimeChange);
    }
    super.dispose();
  }

  void _handleRealtimeChange(dynamic _) {
    if (!mounted) return;
    setState(() => future = _load());
  }

  Future<List<FamilyItem>> _load() async {
    final rows = await widget.repository.list('cartas');
    return rows
        .where((item) => item.title.startsWith('${widget.prefix}:'))
        .map(_withoutPrefix)
        .toList();
  }

  FamilyItem _withoutPrefix(FamilyItem item) {
    final data = Map<String, dynamic>.from(item.data);
    data['titulo'] = item.title
        .replaceFirst(RegExp('^${RegExp.escape(widget.prefix)}:\\s*'), '');
    return FamilyItem(data);
  }

  @override
  Widget build(BuildContext context) {
    final canWrite = widget.auth.user != null;
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LoveBackground(
        child: FutureBuilder<List<FamilyItem>>(
          future: future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const PageSkeleton(cards: 3);
            final items = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async {
                setState(() => future = _load());
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 112),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: AppPageHeader(
                        title: widget.title,
                        subtitle: canWrite
                            ? 'Escreva e edite os textos desta página.'
                            : 'Textos publicados para a família.',
                        icon: Icons.edit_note_outlined,
                        actionLabel: canWrite ? 'Escrever' : null,
                        actionIcon: Icons.edit_outlined,
                        onAction: canWrite ? () => _openEditor() : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: items.isEmpty
                          ? LovePanel(
                              child: Text(
                                canWrite
                                    ? 'Nenhum texto escrito ainda.'
                                    : 'Ainda não há textos publicados.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: palette.muted),
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final columns =
                                    constraints.maxWidth >= 860 ? 2 : 1;
                                return GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: columns,
                                  childAspectRatio: columns == 1 ? 1.75 : 1.18,
                                  crossAxisSpacing: 24,
                                  mainAxisSpacing: 24,
                                  children: [
                                    for (final item in items)
                                      InkWell(
                                        onLongPress: canWrite
                                            ? () => _openEditor(item)
                                            : null,
                                        child: Stack(
                                          children: [
                                            Positioned.fill(
                                              child: LoveTextCard(
                                                title: item.title,
                                                body: item.subtitle,
                                                footer: item.data['data']
                                                        ?.toString()
                                                        .split('T')
                                                        .first ??
                                                    '',
                                              ),
                                            ),
                                            if (canWrite)
                                              Positioned(
                                                right: 8,
                                                top: 8,
                                                child: Row(
                                                  children: [
                                                    IconButton(
                                                      onPressed: () =>
                                                          _openEditor(item),
                                                      icon: const Icon(
                                                          Icons.edit_outlined),
                                                    ),
                                                    IconButton(
                                                      onPressed: () =>
                                                          _delete(item),
                                                      icon: const Icon(
                                                          Icons.delete_outline),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openEditor([FamilyItem? item]) {
    showAppSheet<void>(
      context: context,
      builder: (_) => _TextEntrySheet(
        title: widget.title,
        item: item,
        onSave: (data) async {
          final payload = {
            'titulo': '${widget.prefix}: ${data['titulo']}',
            'conteudo': data['conteudo'],
          };
          if (item == null) {
            await widget.repository.create('cartas', payload);
          } else {
            await widget.repository.update('cartas', item.id, payload);
          }
          widget.toast.success('Texto salvo.');
          setState(() => future = _load());
        },
      ),
    );
  }

  Future<void> _delete(FamilyItem item) async {
    await widget.repository.delete('cartas', item.id);
    widget.toast.success('Texto removido.');
    setState(() => future = _load());
  }
}

const _events = ['cartas.created', 'cartas.updated', 'cartas.deleted'];

class _TextEntrySheet extends StatefulWidget {
  const _TextEntrySheet({required this.title, required this.onSave, this.item});

  final String title;
  final FamilyItem? item;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  @override
  State<_TextEntrySheet> createState() => _TextEntrySheetState();
}

class _TextEntrySheetState extends State<_TextEntrySheet> {
  final title = TextEditingController();
  final content = TextEditingController();
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item != null) {
      title.text = item.title;
      content.text = item.subtitle;
    }
  }

  @override
  void dispose() {
    title.dispose();
    content.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await widget.onSave({
        'titulo': title.text.trim(),
        'conteudo': content.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSheetHeader(
            title:
                widget.item == null ? 'Escrever em ${widget.title}' : 'Editar',
            subtitle: 'Registre um texto especial para aparecer no app.',
            icon: Icons.edit_note_outlined,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: title,
            decoration: const InputDecoration(labelText: 'Título'),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: content,
            decoration: const InputDecoration(labelText: 'Texto'),
            minLines: 5,
            maxLines: 10,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 18),
          AppSheetActions(
            onCancel: saving ? null : () => Navigator.pop(context),
            onSave: saving ? null : _save,
            loading: saving,
          ),
        ],
      ),
    );
  }
}
