import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/love_background.dart';
import '../../../core/widgets/love_text_card.dart';
import '../../../core/widgets/section_title.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../data/family_repository.dart';
import '../../../data/models.dart';

class ResourcePage extends StatefulWidget {
  const ResourcePage(
      {super.key,
      required this.title,
      required this.resource,
      required this.repository,
      required this.toast});

  final String title;
  final String resource;
  final FamilyRepository repository;
  final ToastController toast;

  @override
  State<ResourcePage> createState() => _ResourcePageState();
}

class _ResourcePageState extends State<ResourcePage> {
  late Future<List<FamilyItem>> future =
      widget.repository.list(widget.resource);
  String _albumFilter = 'Todos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LoveBackground(
        child: FutureBuilder<List<FamilyItem>>(
          future: future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const PageSkeleton();
            final items = snapshot.data!;
            final visibleItems =
                widget.resource == 'fotos' && _albumFilter != 'Todos'
                    ? items.where((item) => item.album == _albumFilter).toList()
                    : items;
            final albums = widget.resource == 'fotos'
                ? _albumsFor(items)
                : const <String>[];
            return RefreshIndicator(
              onRefresh: () async {
                setState(
                    () => future = widget.repository.list(widget.resource));
                widget.toast
                    .info('Atualizando ${widget.title.toLowerCase()}...');
              },
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                    24, widget.resource == 'fotos' ? 32 : 80, 24, 32),
                children: [
                  _ResourceHeader(
                    title: _titleFor(widget.resource, widget.title),
                    subtitle: _subtitleFor(widget.resource),
                    actionLabel: _actionLabelFor(widget.resource),
                    onPressed: () => _openCreate(context),
                  ),
                  const SizedBox(height: 32),
                  if (widget.resource == 'fotos') ...[
                    _AlbumFilter(
                      albums: albums,
                      selected: _albumFilter,
                      onSelected: (album) =>
                          setState(() => _albumFilter = album),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: widget.resource == 'fotos' ? 1280 : 1200),
                      child: visibleItems.isEmpty
                          ? Card(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text('${widget.title} ainda está vazio.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: muted)),
                              ),
                            )
                          : _ResourceGrid(
                              resource: widget.resource,
                              items: visibleItems,
                              onEdit: _openEdit,
                              onDelete: _deleteItem,
                              onView: _openPhotoViewer,
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        onPressed: () => _openCreate(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openCreate(BuildContext context) {
    showAppSheet<void>(
      context: context,
      builder: (context) => widget.resource == 'fotos'
          ? PhotoMemorySheet(
              repository: widget.repository,
              toast: widget.toast,
              onSave: (data) async {
                await widget.repository.create(widget.resource, data);
                widget.toast.success('Memória salva com sucesso.');
                setState(
                    () => future = widget.repository.list(widget.resource));
              },
            )
          : ResourceDialog(
              title: widget.title,
              resource: widget.resource,
              onSave: (data) async {
                await widget.repository.create(widget.resource, data);
                widget.toast.success('Item salvo com sucesso.');
                setState(
                    () => future = widget.repository.list(widget.resource));
              },
            ),
    );
  }

  void _openEdit(FamilyItem item) {
    showAppSheet<void>(
      context: context,
      builder: (context) => widget.resource == 'fotos'
          ? PhotoMemorySheet(
              repository: widget.repository,
              toast: widget.toast,
              item: item,
              onSave: (data) async {
                await widget.repository.update(widget.resource, item.id, data);
                widget.toast.success('Memória atualizada.');
                setState(
                    () => future = widget.repository.list(widget.resource));
              },
            )
          : ResourceDialog(
              title: widget.title,
              resource: widget.resource,
              initial: item,
              onSave: (data) async {
                await widget.repository.update(widget.resource, item.id, data);
                widget.toast.success('Item atualizado.');
                setState(
                    () => future = widget.repository.list(widget.resource));
              },
            ),
    );
  }

  Future<void> _deleteItem(FamilyItem item) async {
    await widget.repository.delete(widget.resource, item.id);
    widget.toast.success(
        widget.resource == 'fotos' ? 'Memória removida.' : 'Item removido.');
    setState(() => future = widget.repository.list(widget.resource));
  }

  void _openPhotoViewer(FamilyItem item) {
    showAppSheet<void>(
      context: context,
      builder: (_) => _PhotoViewer(item: item),
    );
  }
}

class _ResourceHeader extends StatelessWidget {
  const _ResourceHeader({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          children: [
            SectionTitle(title, size: 44),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: muted,
                    fontSize: 22,
                    height: 1.45,
                    fontFamily: 'serif'),
              ),
            ],
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add),
              label: Text(actionLabel),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                textStyle: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'serif',
                    fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourceGrid extends StatelessWidget {
  const _ResourceGrid({
    required this.resource,
    required this.items,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  });

  final String resource;
  final List<FamilyItem> items;
  final ValueChanged<FamilyItem> onEdit;
  final ValueChanged<FamilyItem> onDelete;
  final ValueChanged<FamilyItem> onView;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = resource == 'fotos'
            ? (constraints.maxWidth >= 1280
                ? 4
                : constraints.maxWidth >= 1024
                    ? 3
                    : constraints.maxWidth >= 640
                        ? 2
                        : 1)
            : (constraints.maxWidth >= 900
                ? 3
                : constraints.maxWidth >= 620
                    ? 2
                    : 1);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          childAspectRatio: resource == 'fotos' ? 1.05 : 1.08,
          crossAxisSpacing: 32,
          mainAxisSpacing: 32,
          children: items.map((item) {
            if (resource == 'fotos') {
              return _PhotoCard(
                  item: item,
                  onEdit: onEdit,
                  onDelete: onDelete,
                  onView: onView);
            }
            return InkWell(
              onLongPress: () => onEdit(item),
              child: LoveTextCard(
                  title: item.title,
                  body:
                      item.subtitle.isEmpty ? 'Sem descrição.' : item.subtitle,
                  footer: _footerFor(resource, item)),
            );
          }).toList(),
        );
      },
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard(
      {required this.item,
      required this.onEdit,
      required this.onDelete,
      required this.onView});

  final FamilyItem item;
  final ValueChanged<FamilyItem> onEdit;
  final ValueChanged<FamilyItem> onDelete;
  final ValueChanged<FamilyItem> onView;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => onView(item),
              child: Container(
                width: double.infinity,
                color: primary.withValues(alpha: .08),
                child: item.tipo == 'video'
                    ? const Icon(Icons.play_circle_fill,
                        color: primary, size: 64)
                    : Image.network(
                        _photoUrl(item),
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                              child: SkeletonBox(
                                  width: 120, height: 120, borderRadius: 18));
                        },
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.photo, color: primary, size: 48),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.album,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: primary, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  item.subtitle.isEmpty
                      ? 'Adicione uma descrição...'
                      : item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: muted, height: 1.35),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                        onPressed: () => onEdit(item),
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Editar'),
                    IconButton(
                        onPressed: () => onDelete(item),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Excluir'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ResourceDialog extends StatefulWidget {
  const ResourceDialog(
      {super.key,
      required this.title,
      required this.resource,
      required this.onSave,
      this.initial});

  final String title;
  final String resource;
  final Future<void> Function(Map<String, dynamic> data) onSave;
  final FamilyItem? initial;

  @override
  State<ResourceDialog> createState() => _ResourceDialogState();
}

class _ResourceDialogState extends State<ResourceDialog> {
  final title = TextEditingController();
  final subtitle = TextEditingController();
  final extra = TextEditingController();

  @override
  void initState() {
    super.initState();
    final item = widget.initial;
    if (item != null) {
      title.text = item.title;
      subtitle.text = item.subtitle;
      extra.text = item.data['linkSpotify']?.toString() ??
          item.data['momento']?.toString() ??
          '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Novo item em ${widget.title}',
              style: const TextStyle(
                  color: primary, fontWeight: FontWeight.w900, fontSize: 22)),
          const SizedBox(height: 16),
          TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Título ou URL')),
          TextField(
              controller: subtitle,
              decoration: const InputDecoration(labelText: 'Texto / artista')),
          TextField(
              controller: extra,
              decoration: const InputDecoration(labelText: 'Extra')),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar')),
              const SizedBox(width: 10),
              AppButton(onPressed: _save, label: 'Salvar'),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final data = switch (widget.resource) {
      'musicas' => {
          'titulo': title.text,
          'artista': subtitle.text,
          'linkSpotify': extra.text,
          'momento': 'Especial',
        },
      'cartas' => {'titulo': title.text, 'conteudo': subtitle.text},
      'fotos' => {
          'url': title.text,
          'texto': subtitle.text,
          'tipo': extra.text == 'video' ? 'video' : 'imagem'
        },
      _ => <String, dynamic>{},
    };
    await widget.onSave(data);
    if (mounted) Navigator.pop(context);
  }
}

class PhotoMemorySheet extends StatefulWidget {
  const PhotoMemorySheet({
    super.key,
    required this.repository,
    required this.toast,
    required this.onSave,
    this.item,
  });

  final FamilyRepository repository;
  final ToastController toast;
  final FamilyItem? item;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  @override
  State<PhotoMemorySheet> createState() => _PhotoMemorySheetState();
}

enum _PickedMediaType { image, video }

class _PhotoMemorySheetState extends State<PhotoMemorySheet> {
  final texto = TextEditingController();
  final album = TextEditingController(text: 'Geral');
  final data = TextEditingController();
  XFile? file;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item != null) {
      texto.text = item.subtitle;
      album.text = item.album;
      data.text = item.data['data']?.toString().split('T').first ?? '';
    }
  }

  @override
  void dispose() {
    texto.dispose();
    album.dispose();
    data.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<_PickedMediaType>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Foto da galeria'),
              onTap: () => Navigator.pop(context, _PickedMediaType.image),
            ),
            ListTile(
              leading: const Icon(Icons.video_library_outlined),
              title: const Text('Vídeo da galeria'),
              onTap: () => Navigator.pop(context, _PickedMediaType.video),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = source == _PickedMediaType.image
        ? await picker.pickImage(source: ImageSource.gallery)
        : await picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => file = picked);
    }
  }

  Future<void> _save() async {
    if (widget.item == null && file == null) {
      widget.toast.error('Escolha uma foto ou vídeo.');
      return;
    }
    setState(() => saving = true);
    try {
      var url = widget.item?.url ?? '';
      var tipo = widget.item?.tipo ?? 'imagem';
      if (file != null) {
        url = await widget.repository.uploadPhotoFile(file!);
        final ext = file!.name.split('.').last.toLowerCase();
        tipo = ['mp4', 'webm'].contains(ext) ? 'video' : 'imagem';
      }
      await widget.onSave({
        'url': url,
        'tipo': tipo,
        'texto': texto.text.trim(),
        'album': album.text.trim().isEmpty ? 'Geral' : album.text.trim(),
        if (data.text.trim().isNotEmpty) 'data': data.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (error) {
      widget.toast.error(error.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.item == null ? 'Adicionar memória' : 'Editar memória',
                style: const TextStyle(
                    color: primary, fontWeight: FontWeight.w900, fontSize: 22)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: saving ? null : _pickFile,
              icon: const Icon(Icons.upload_file),
              label: Text(file == null ? 'Escolher foto ou vídeo' : file!.name),
            ),
            const SizedBox(height: 12),
            TextField(
                controller: album,
                decoration: const InputDecoration(labelText: 'Álbum')),
            TextField(
                controller: texto,
                decoration: const InputDecoration(labelText: 'Descrição'),
                minLines: 2,
                maxLines: 4),
            TextField(
                controller: data,
                decoration:
                    const InputDecoration(labelText: 'Data (AAAA-MM-DD)')),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar')),
                const SizedBox(width: 10),
                AppButton(onPressed: _save, label: 'Salvar', loading: saving),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumFilter extends StatelessWidget {
  const _AlbumFilter(
      {required this.albums, required this.selected, required this.onSelected});

  final List<String> albums;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final album in albums)
            ChoiceChip(
              label: Text(album),
              selected: selected == album,
              onSelected: (_) => onSelected(album),
            ),
        ],
      ),
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.item});

  final FamilyItem item;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(item.album,
              style: const TextStyle(
                  color: primary, fontWeight: FontWeight.w900, fontSize: 22)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: item.tipo == 'video'
                ? Container(
                    height: 260,
                    color: primary.withValues(alpha: .08),
                    alignment: Alignment.center,
                    child: const Icon(Icons.play_circle_fill,
                        color: primary, size: 72),
                  )
                : Image.network(_photoUrl(item), fit: BoxFit.contain),
          ),
          if (item.subtitle.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(item.subtitle,
                style: const TextStyle(color: muted, height: 1.4)),
          ],
        ],
      ),
    );
  }
}

String _titleFor(String resource, String fallback) {
  return switch (resource) {
    'musicas' => 'Playlist do Nosso Amor',
    'cartas' => 'Cartas de Amor',
    'fotos' => 'Nossa Galeria de Memórias',
    _ => fallback,
  };
}

List<String> _albumsFor(List<FamilyItem> items) {
  final albums = {'Todos', ...items.map((item) => item.album)};
  return albums.toList()
    ..sort((a, b) => a == 'Todos'
        ? -1
        : b == 'Todos'
            ? 1
            : a.compareTo(b));
}

String _photoUrl(FamilyItem item) {
  if (item.url.startsWith('http')) return item.url;
  return AppConfig.apiUri(
          '/fotos/file?path=${Uri.encodeQueryComponent(item.url)}')
      .toString();
}

String _subtitleFor(String resource) {
  return switch (resource) {
    'musicas' =>
      'Cada música conta uma história nossa. Uma melodia que nos faz sorrir, dançar e reviver momentos especiais do nosso amor.',
    'cartas' =>
      'Um espaço especial onde guardo todas as minhas declarações de amor para você. Cada carta é um pedacinho do meu coração transformado em palavras.',
    _ => '',
  };
}

String _actionLabelFor(String resource) {
  return switch (resource) {
    'musicas' => 'Adicionar Nova Música',
    'cartas' => 'Escrever Nova Carta',
    'fotos' => 'Adicionar Memória',
    _ => 'Adicionar',
  };
}

String? _footerFor(String resource, FamilyItem item) {
  return switch (resource) {
    'musicas' => item.data['momento']?.toString(),
    _ => null,
  };
}
