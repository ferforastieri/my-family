import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/app_config.dart';
import '../../../core/api/query_keys.dart';
import '../../../core/query/app_query.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_fixed_header_scroll_view.dart';
import '../../../core/widgets/app_pagination.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/love_action_card.dart';
import '../../../core/widgets/love_background.dart';
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
  static const _pageLimit = 24;
  int page = 1;
  String? selectedAlbum;

  @override
  void initState() {
    super.initState();
    for (final event in _resourceEvents(widget.resource)) {
      widget.repository.socket.on(event, _handleRealtimeChange);
    }
  }

  @override
  void dispose() {
    for (final event in _resourceEvents(widget.resource)) {
      widget.repository.socket.off(event, _handleRealtimeChange);
    }
    super.dispose();
  }

  void _handleRealtimeChange(dynamic _) {
    if (!mounted) return;
    _invalidate();
  }

  void _reload({int? nextPage}) {
    setState(() {
      page = nextPage ?? page;
    });
    _invalidate();
  }

  void _selectAlbum(String? album) {
    setState(() {
      selectedAlbum = album;
      page = 1;
    });
    _invalidate();
  }

  void _invalidate() {
    invalidateQueries(context, QueryKeys.resourceScope(widget.resource));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LoveBackground(
        child: AppQuery<List<PhotoAlbumSummary>>(
          queryKey: widget.resource == 'fotos'
              ? QueryKeys.photoAlbums()
              : const ['resource', 'albums', 'disabled'],
          queryFn: () => widget.resource == 'fotos'
              ? widget.repository.listPhotoAlbums()
              : Future.value(<PhotoAlbumSummary>[]),
          loading: const PageSkeleton(),
          builder: (context, albums, _) =>
              AppQuery<PaginatedResult<FamilyItem>>(
            key: ValueKey('${widget.resource}-$page-${selectedAlbum ?? 'all'}'),
            queryKey: QueryKeys.resource(
              widget.resource,
              page,
              _pageLimit,
              album: selectedAlbum,
            ),
            queryFn: () => widget.repository.listPage(
              widget.resource,
              page,
              _pageLimit,
              album: selectedAlbum,
            ),
            loading: const PageSkeleton(),
            builder: (context, result, refetch) {
              final items = result.items;
              return AppFixedHeaderScrollView(
                header: _ResourceHero(
                  resource: widget.resource,
                  title: _titleFor(widget.resource, widget.title),
                  subtitle: _subtitleFor(widget.resource),
                  actionLabel: _actionLabelFor(widget.resource),
                  onPressed: () => _openCreate(context),
                ),
                children: [
                  if (widget.resource != 'fotos' &&
                      widget.resource != 'musicas' &&
                      widget.resource != 'cartas') ...[
                    _ResourceMetrics(
                      resource: widget.resource,
                      total: result.total,
                      visible: items.length,
                      albums: albums.length,
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (widget.resource == 'fotos') ...[
                    _AlbumFilter(
                      albums: albums,
                      selectedAlbum: selectedAlbum,
                      onSelected: _selectAlbum,
                    ),
                    const SizedBox(height: 16),
                  ],
                  items.isEmpty
                      ? _EmptyResourceState(
                          title: selectedAlbum == null
                              ? '${widget.title} ainda está vazio.'
                              : 'Nenhuma memória nesse álbum.',
                          actionLabel: _actionLabelFor(widget.resource),
                          onPressed: () => _openCreate(context),
                        )
                      : _ResourceGrid(
                          resource: widget.resource,
                          items: items,
                          onEdit: _openEdit,
                          onDelete: _deleteItem,
                          onView: _openPhotoViewer,
                        ),
                  const SizedBox(height: 12),
                  AppPagination(
                    page: result.page,
                    pages: result.pages,
                    total: result.total,
                    onPrevious: result.hasPrevious
                        ? () => _reload(nextPage: result.page - 1)
                        : null,
                    onNext: result.hasNext
                        ? () => _reload(nextPage: result.page + 1)
                        : null,
                  ),
                ],
              );
            },
          ),
        ),
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
                widget.toast.backendSuccess(widget.repository.takeMessage());
                _reload(nextPage: 1);
              },
            )
          : ResourceDialog(
              title: widget.title,
              resource: widget.resource,
              onSave: (data) async {
                await widget.repository.create(widget.resource, data);
                widget.toast.backendSuccess(widget.repository.takeMessage());
                _reload(nextPage: 1);
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
                widget.toast.backendSuccess(widget.repository.takeMessage());
                _reload();
              },
            )
          : ResourceDialog(
              title: widget.title,
              resource: widget.resource,
              initial: item,
              onSave: (data) async {
                await widget.repository.update(widget.resource, item.id, data);
                widget.toast.backendSuccess(widget.repository.takeMessage());
                _reload();
              },
            ),
    );
  }

  Future<void> _deleteItem(FamilyItem item) async {
    await widget.repository.delete(widget.resource, item.id);
    widget.toast.success(
        widget.resource == 'fotos' ? 'Memória removida.' : 'Item removido.');
    _reload();
  }

  void _openPhotoViewer(FamilyItem item) {
    if (widget.resource == 'cartas') {
      showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: .58),
        builder: (_) => _LetterReader(item: item),
      );
      return;
    }
    showAppSheet<void>(
      context: context,
      builder: (_) => _PhotoViewer(item: item),
    );
  }
}

List<String> _resourceEvents(String resource) {
  return [
    '$resource.created',
    '$resource.updated',
    '$resource.deleted',
  ];
}

class _ResourceHero extends StatelessWidget {
  const _ResourceHero({
    required this.resource,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onPressed,
  });

  final String resource;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppPageHeader(
      title: title,
      subtitle: subtitle,
      icon: _resourceIcon(resource),
      actionLabel: actionLabel,
      actionIcon: Icons.add,
      onAction: onPressed,
    );
  }
}

class _ResourceMetrics extends StatelessWidget {
  const _ResourceMetrics({
    required this.resource,
    required this.total,
    required this.visible,
    required this.albums,
  });

  final String resource;
  final int total;
  final int visible;
  final int albums;

  @override
  Widget build(BuildContext context) {
    final values = [
      _MetricValue(
          _resourceCountLabel(resource), total, _resourceIcon(resource)),
      if (resource == 'fotos')
        _MetricValue('Álbuns', albums, Icons.collections_bookmark_outlined),
      if (resource == 'fotos')
        _MetricValue('Na visão atual', visible, Icons.filter_alt_outlined),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 760 ? values.length : 1;
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: columns,
        childAspectRatio: constraints.maxWidth >= 760 ? 3.6 : 4.8,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        children: values.map((value) => _ResourceMetricCard(value)).toList(),
      );
    });
  }
}

class _MetricValue {
  const _MetricValue(this.label, this.value, this.icon);
  final String label;
  final int value;
  final IconData icon;
}

class _ResourceMetricCard extends StatelessWidget {
  const _ResourceMetricCard(this.value);

  final _MetricValue value;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return LovePanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: palette.primary.withValues(alpha: .12),
            foregroundColor: palette.primary,
            child: Icon(value.icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${value.value}',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900)),
                Text(value.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: palette.muted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumFilter extends StatelessWidget {
  const _AlbumFilter({
    required this.albums,
    required this.selectedAlbum,
    required this.onSelected,
  });

  static const _allAlbumsValue = '__all_albums__';

  final List<PhotoAlbumSummary> albums;
  final String? selectedAlbum;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final total = albums.fold<int>(0, (sum, album) => sum + album.count);
    final selectedLabel = selectedAlbum ?? 'Todos os álbuns';
    return LovePanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.collections_bookmark_outlined,
                color: palette.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _openAlbumSheet(context, total),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                side: BorderSide(color: palette.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filtrar por álbum',
                          style: TextStyle(
                            color: palette.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedAlbum == null
                              ? '$selectedLabel ($total)'
                              : selectedLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.foreground,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down, color: palette.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAlbumSheet(BuildContext context, int total) async {
    final selected = await showAppSheet<String?>(
      context: context,
      builder: (_) => _AlbumOptionsSheet(
        albums: albums,
        selectedAlbum: selectedAlbum,
        total: total,
      ),
    );
    if (selected == _allAlbumsValue) {
      onSelected(null);
    } else if (selected != null) {
      onSelected(selected);
    }
  }
}

class _AlbumOptionsSheet extends StatelessWidget {
  const _AlbumOptionsSheet({
    required this.albums,
    required this.selectedAlbum,
    required this.total,
  });

  final List<PhotoAlbumSummary> albums;
  final String? selectedAlbum;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSheetHeader(
          title: 'Escolher álbum',
          subtitle: 'Filtre as memórias pelo álbum desejado.',
          icon: Icons.collections_bookmark_outlined,
        ),
        const SizedBox(height: 12),
        _OptionTile(
          icon: Icons.photo_library_outlined,
          title: 'Todos os álbuns',
          subtitle: '$total memórias',
          selected: selectedAlbum == null,
          onTap: () => Navigator.pop(context, _AlbumFilter._allAlbumsValue),
        ),
        for (final album in albums)
          _OptionTile(
            icon: Icons.photo_album_outlined,
            title: album.album,
            subtitle: '${album.count} memórias',
            selected: selectedAlbum == album.album,
            onTap: () => Navigator.pop(context, album.album),
          ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: selected ? palette.primary : palette.muted),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle),
      trailing:
          selected ? Icon(Icons.check_circle, color: palette.primary) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}

class _EmptyResourceState extends StatelessWidget {
  const _EmptyResourceState({
    required this.title,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return LovePanel(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(Icons.favorite_border, color: palette.primary, size: 42),
          const SizedBox(height: 10),
          Text(title,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          AppButton(onPressed: onPressed, label: actionLabel, icon: Icons.add),
        ],
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
        final visualCards = resource == 'fotos' ||
            resource == 'musicas' ||
            resource == 'cartas';
        final columns = visualCards
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
          childAspectRatio: visualCards ? 1.05 : 1.08,
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
            if (resource == 'musicas') {
              return _MusicCard(
                item: item,
                onEdit: onEdit,
                onDelete: onDelete,
              );
            }
            if (resource == 'cartas') {
              return _LetterCard(
                item: item,
                onEdit: onEdit,
                onDelete: onDelete,
                onView: onView,
              );
            }
            return _TextResourceCard(
              resource: resource,
              item: item,
              onEdit: onEdit,
              onDelete: onDelete,
            );
          }).toList(),
        );
      },
    );
  }
}

class _TextResourceCard extends StatelessWidget {
  const _TextResourceCard({
    required this.resource,
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final String resource;
  final FamilyItem item;
  final ValueChanged<FamilyItem> onEdit;
  final ValueChanged<FamilyItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: LoveActionCard(
              title: item.title,
              description:
                  item.subtitle.isEmpty ? 'Sem descrição.' : item.subtitle,
              icon: _resourceIcon(resource),
              onTap: () => onEdit(item),
              trailing: Icon(Icons.chevron_right, color: palette.primary),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 54),
            ),
          ),
          Positioned(
            left: 18,
            right: 10,
            bottom: 8,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _footerFor(resource, item) ?? _resourceCountLabel(resource),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: palette.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12),
                  ),
                ),
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
          ),
        ],
      ),
    );
  }
}

class _MusicCard extends StatelessWidget {
  const _MusicCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final FamilyItem item;
  final ValueChanged<FamilyItem> onEdit;
  final ValueChanged<FamilyItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final moment = item.data['momento']?.toString().trim();
    final link = item.data['linkSpotify']?.toString().trim();
    final hasLink = link != null && link.isNotEmpty;
    return LovePanel(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: InkWell(
                onTap: () => onEdit(item),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            palette.primary.withValues(alpha: .88),
                            palette.primaryDark.withValues(alpha: .88),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .22),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: .26)),
                            ),
                            child: const Icon(Icons.music_note,
                                color: Colors.white, size: 30),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1.08,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.subtitle.isEmpty
                                ? 'Artista não informado'
                                : item.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .86),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (moment != null && moment.isNotEmpty)
                      Positioned(
                        top: 10,
                        left: 10,
                        right: 10,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: .32),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              child: Text(
                                moment,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasLink ? 'Link do Spotify salvo' : 'Sem link do Spotify',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasLink ? palette.primary : palette.muted,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _LetterCard extends StatelessWidget {
  const _LetterCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  });

  final FamilyItem item;
  final ValueChanged<FamilyItem> onEdit;
  final ValueChanged<FamilyItem> onDelete;
  final ValueChanged<FamilyItem> onView;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final preview = item.subtitle.trim();
    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: palette.primary.withValues(alpha: .06),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              top: 18,
              bottom: 58,
              child: Material(
                color: palette.card,
                elevation: 3,
                shadowColor: Colors.black.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(4),
                child: InkWell(
                  onTap: () => onView(item),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 52),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PARA MEU AMOR',
                          style: TextStyle(
                            color: palette.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .extension<AppTextThemes>()!
                              .display
                              .copyWith(
                                color: palette.foreground,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                height: 1.08,
                              ),
                        ),
                        const SizedBox(height: 9),
                        Expanded(
                          child: Text(
                            preview.isEmpty
                                ? 'Uma carta esperando palavras de amor.'
                                : preview,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.muted,
                              height: 1.42,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 112,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _EnvelopePainter(
                    color: palette.primary.withValues(alpha: .30),
                    lineColor: palette.primary.withValues(alpha: .42),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 8,
              bottom: 5,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Abrir carta',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => onEdit(item),
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    onPressed: () => onDelete(item),
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Excluir',
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
    final palette = Theme.of(context).extension<AppPalette>()!;
    return LovePanel(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => onView(item),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: palette.primary.withValues(alpha: .08),
                      child: item.tipo == 'video'
                          ? Icon(Icons.play_circle_fill,
                              color: palette.primary, size: 64)
                          : Image.network(
                              _photoUrl(item),
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                    child: SkeletonBox(
                                        width: 120,
                                        height: 120,
                                        borderRadius: 18));
                              },
                              errorBuilder: (_, __, ___) => Icon(Icons.photo,
                                  color: palette.primary, size: 48),
                            ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .45),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          child: Text(item.album,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.subtitle.isEmpty
                        ? 'Adicione uma descrição...'
                        : item.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: palette.muted, height: 1.35),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.tipo == 'video' ? 'Vídeo' : 'Foto',
                          style: TextStyle(
                              color: palette.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12),
                        ),
                      ),
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
  bool saving = false;

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
          AppSheetHeader(
            title: widget.initial == null
                ? 'Novo item em ${widget.title}'
                : 'Editar ${widget.title}',
            subtitle: 'Preencha as informações e salve a lembrança.',
            icon: _resourceIcon(widget.resource),
          ),
          const SizedBox(height: 16),
          TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Título ou URL'),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save()),
          const SizedBox(height: 10),
          TextField(
            controller: subtitle,
            decoration: InputDecoration(
              labelText:
                  widget.resource == 'cartas' ? 'Carta' : 'Texto / artista',
            ),
            minLines: widget.resource == 'cartas' ? 7 : 1,
            maxLines: widget.resource == 'cartas' ? 12 : 1,
            textInputAction: widget.resource == 'cartas'
                ? TextInputAction.newline
                : TextInputAction.done,
            onSubmitted: widget.resource == 'cartas' ? null : (_) => _save(),
          ),
          if (widget.resource != 'cartas') ...[
            const SizedBox(height: 10),
            TextField(
                controller: extra,
                decoration: const InputDecoration(labelText: 'Extra'),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save()),
          ],
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

  Future<void> _save() async {
    setState(() => saving = true);
    try {
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
    } finally {
      if (mounted) setState(() => saving = false);
    }
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
  DateTime? date;
  XFile? file;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item != null) {
      texto.text = item.subtitle;
      album.text = item.album;
      date = DateTime.tryParse(item.data['data']?.toString() ?? '');
    }
  }

  @override
  void dispose() {
    texto.dispose();
    album.dispose();
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
        if (date != null) 'data': _datePayload(date!),
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
    final palette = Theme.of(context).extension<AppPalette>()!;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.item == null ? 'Adicionar memória' : 'Editar memória',
                style: TextStyle(
                    color: palette.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              'Escolha a mídia, organize por álbum e marque a data pelo calendário.',
              style: TextStyle(
                color: palette.muted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: saving ? null : _pickFile,
              icon: const Icon(Icons.upload_file),
              label: Text(file == null ? 'Escolher foto ou vídeo' : file!.name),
            ),
            const SizedBox(height: 12),
            TextField(
                controller: album,
                decoration: const InputDecoration(labelText: 'Álbum'),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save()),
            const SizedBox(height: 10),
            TextField(
                controller: texto,
                decoration: const InputDecoration(labelText: 'Descrição'),
                minLines: 2,
                maxLines: 4,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save()),
            const SizedBox(height: 10),
            AppDateField(
              label: 'Data da memória',
              value: date,
              onChanged: (value) => setState(() => date = value),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            ),
            const SizedBox(height: 18),
            AppSheetActions(
              onCancel: saving ? null : () => Navigator.pop(context),
              onSave: saving ? null : _save,
              loading: saving,
            ),
          ],
        ),
      ),
    );
  }
}

String _datePayload(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

class _LetterReader extends StatelessWidget {
  const _LetterReader({required this.item});

  final FamilyItem item;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final date = item.data['data']?.toString().split('T').first ?? '';
    final screenHeight = MediaQuery.sizeOf(context).height;
    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 900,
          maxHeight: screenHeight * .90,
        ),
        child: SingleChildScrollView(
          child: Material(
            color: palette.card,
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 30, 30, 34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'PARA MEU AMOR',
                          style: TextStyle(
                            color: palette.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (date.isNotEmpty)
                        Text(
                          date,
                          style: TextStyle(
                            color: palette.muted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    item.title,
                    style: Theme.of(context)
                        .extension<AppTextThemes>()!
                        .display
                        .copyWith(
                          color: palette.foreground,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          height: 1.12,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 52,
                    height: 2,
                    color: palette.primary.withValues(alpha: .48),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      color: palette.foreground,
                      fontSize: 17,
                      height: 1.72,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Com todo o meu amor,',
                          style: TextStyle(
                            color: palette.muted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Icon(Icons.favorite, color: palette.primary, size: 22),
                      ],
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

class _EnvelopePainter extends CustomPainter {
  const _EnvelopePainter({required this.color, required this.lineColor});

  final Color color;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final back = Paint()..color = Color.alphaBlend(color, Colors.white);
    final flap = Paint()
      ..color = Color.alphaBlend(
        color.withValues(alpha: .78),
        Colors.white,
      );
    final front = Paint()
      ..color = Color.alphaBlend(
        color.withValues(alpha: .92),
        Colors.white,
      );
    final line = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(8),
    );
    canvas.drawRRect(rect, back);

    final openFlap = Path()
      ..moveTo(5, size.height * .22)
      ..lineTo(size.width / 2, size.height * .68)
      ..lineTo(size.width - 5, size.height * .22)
      ..lineTo(size.width / 2, 0)
      ..close();
    canvas.drawPath(openFlap, flap);
    canvas.drawPath(openFlap, line);

    final leftFold = Path()
      ..moveTo(0, size.height * .28)
      ..lineTo(size.width / 2, size.height * .66)
      ..lineTo(0, size.height)
      ..close();
    final rightFold = Path()
      ..moveTo(size.width, size.height * .28)
      ..lineTo(size.width / 2, size.height * .66)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(leftFold, front);
    canvas.drawPath(rightFold, front);

    final frontFold = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, size.height * .57)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(frontFold, front);
    canvas.drawPath(leftFold, line);
    canvas.drawPath(rightFold, line);
    canvas.drawPath(frontFold, line);

    final sealCenter = Offset(size.width / 2, size.height * .60);
    canvas.drawCircle(
      sealCenter,
      14,
      Paint()..color = const Color(0xffc93f78),
    );
    final heart = Path()
      ..moveTo(sealCenter.dx, sealCenter.dy + 5)
      ..cubicTo(
        sealCenter.dx - 12,
        sealCenter.dy - 2,
        sealCenter.dx - 7,
        sealCenter.dy - 10,
        sealCenter.dx,
        sealCenter.dy - 4,
      )
      ..cubicTo(
        sealCenter.dx + 7,
        sealCenter.dy - 10,
        sealCenter.dx + 12,
        sealCenter.dy - 2,
        sealCenter.dx,
        sealCenter.dy + 5,
      );
    canvas.drawPath(heart, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_EnvelopePainter oldDelegate) {
    return color != oldDelegate.color || lineColor != oldDelegate.lineColor;
  }
}

class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.item});

  final FamilyItem item;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(item.album,
              style: TextStyle(
                  color: palette.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 22)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: item.tipo == 'video'
                ? Container(
                    height: 260,
                    color: palette.primary.withValues(alpha: .08),
                    alignment: Alignment.center,
                    child: Icon(Icons.play_circle_fill,
                        color: palette.primary, size: 72),
                  )
                : Image.network(_photoUrl(item), fit: BoxFit.contain),
          ),
          if (item.subtitle.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(item.subtitle,
                style: TextStyle(color: palette.muted, height: 1.4)),
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

IconData _resourceIcon(String resource) {
  return switch (resource) {
    'musicas' => Icons.music_note_outlined,
    'cartas' => Icons.card_giftcard_outlined,
    'fotos' => Icons.photo_library_outlined,
    _ => Icons.favorite_outline,
  };
}

String _resourceCountLabel(String resource) {
  return switch (resource) {
    'musicas' => 'Músicas',
    'cartas' => 'Cartas',
    'fotos' => 'Memórias',
    _ => 'Itens',
  };
}
