import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/api/query_keys.dart';
import '../../../core/query/app_query.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_pagination.dart';
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
  static const _pageLimit = 12;

  int page = 1;

  @override
  void initState() {
    super.initState();
    for (final event in _journeyEvents) {
      widget.repository.socket.on(event, _handleRealtimeChange);
    }
  }

  @override
  void dispose() {
    for (final event in _journeyEvents) {
      widget.repository.socket.off(event, _handleRealtimeChange);
    }
    super.dispose();
  }

  void _handleRealtimeChange(dynamic _) {
    if (!mounted) return;
    _invalidate();
  }

  void _invalidate() {
    invalidateQueries(context, QueryKeys.textCollectionScope(widget.prefix));
  }

  Future<PaginatedResult<FamilyItem>> _fetchTexts() async {
    final result = await widget.repository.listPage(
      'journey',
      page,
      _pageLimit,
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final canWrite = widget.auth.user != null;
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LoveBackground(
        child: AppQuery<PaginatedResult<FamilyItem>>(
          queryKey: QueryKeys.textCollection(widget.prefix, page, _pageLimit),
          queryFn: _fetchTexts,
          loading: const PageSkeleton(cards: 3),
          builder: (context, result, refetch) {
            final items = result.items;
            return RefreshIndicator(
              onRefresh: () async {
                await refetch();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 112),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
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
                      constraints: const BoxConstraints(maxWidth: 1200),
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
                                return Column(
                                  children: [
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: items.length,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: columns,
                                        mainAxisExtent:
                                            columns == 1 ? 250 : 240,
                                        crossAxisSpacing: 24,
                                        mainAxisSpacing: 24,
                                      ),
                                      itemBuilder: (context, index) {
                                        final item = items[index];
                                        return InkWell(
                                          onTap: () => _openReader(item),
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
                                                        icon: const Icon(Icons
                                                            .edit_outlined),
                                                      ),
                                                      IconButton(
                                                        onPressed: () =>
                                                            _delete(item),
                                                        icon: const Icon(Icons
                                                            .delete_outline),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    if (result.pages > 1) ...[
                                      const SizedBox(height: 16),
                                      AppPagination(
                                        page: result.page,
                                        pages: result.pages,
                                        total: result.total,
                                        onPrevious: result.hasPrevious
                                            ? () {
                                                setState(() {
                                                  page -= 1;
                                                });
                                              }
                                            : null,
                                        onNext: result.hasNext
                                            ? () {
                                                setState(() {
                                                  page += 1;
                                                });
                                              }
                                            : null,
                                      ),
                                    ],
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
            'titulo': data['titulo'],
            'conteudo': data['conteudo'],
          };
          if (item == null) {
            await widget.repository.create('journey', payload);
            page = 1;
          } else {
            await widget.repository.update('journey', item.id, payload);
          }
          widget.toast.backendSuccess(widget.repository.takeMessage());
          _invalidate();
        },
      ),
    );
  }

  void _openReader(FamilyItem item) {
    showAppSheet<void>(
      context: context,
      builder: (_) => _TextReaderSheet(item: item),
    );
  }

  Future<void> _delete(FamilyItem item) async {
    await widget.repository.delete('journey', item.id);
    widget.toast.backendSuccess(widget.repository.takeMessage());
    _invalidate();
  }
}

const _journeyEvents = [
  'journey.created',
  'journey.updated',
  'journey.deleted',
];

class _TextReaderSheet extends StatelessWidget {
  const _TextReaderSheet({required this.item});

  final FamilyItem item;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final date = item.data['data']?.toString().split('T').first ?? '';
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSheetHeader(
            title: item.title,
            icon: Icons.auto_stories_outlined,
          ),
          const SizedBox(height: 18),
          Text(
            item.subtitle,
            style: TextStyle(
              color: palette.foreground,
              fontSize: 17,
              height: 1.55,
            ),
          ),
          if (date.isNotEmpty) ...[
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                date,
                style: TextStyle(
                  color: palette.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

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
