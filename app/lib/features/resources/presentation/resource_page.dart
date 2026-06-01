import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/love_background.dart';
import '../../../core/widgets/love_text_card.dart';
import '../../../core/widgets/section_title.dart';
import '../../../data/family_repository.dart';
import '../../../data/models.dart';

class ResourcePage extends StatefulWidget {
  const ResourcePage({super.key, required this.title, required this.resource, required this.repository});

  final String title;
  final String resource;
  final FamilyRepository repository;

  @override
  State<ResourcePage> createState() => _ResourcePageState();
}

class _ResourcePageState extends State<ResourcePage> {
  late Future<List<FamilyItem>> future = widget.repository.list(widget.resource);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LoveBackground(
        child: FutureBuilder<List<FamilyItem>>(
          future: future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final items = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async => setState(() => future = widget.repository.list(widget.resource)),
              child: ListView(
                padding: EdgeInsets.fromLTRB(24, widget.resource == 'fotos' ? 32 : 80, 24, 32),
                children: [
                  _ResourceHeader(
                    title: _titleFor(widget.resource, widget.title),
                    subtitle: _subtitleFor(widget.resource),
                    actionLabel: _actionLabelFor(widget.resource),
                    onPressed: () => _openCreate(context),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: widget.resource == 'fotos' ? 1280 : 1200),
                      child: items.isEmpty
                          ? Card(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text('${widget.title} ainda está vazio.', textAlign: TextAlign.center, style: const TextStyle(color: muted)),
                              ),
                            )
                          : _ResourceGrid(resource: widget.resource, items: items),
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
    showDialog<void>(
      context: context,
      builder: (context) => ResourceDialog(
        title: widget.title,
        resource: widget.resource,
        onSave: (data) async {
          await widget.repository.create(widget.resource, data);
          setState(() => future = widget.repository.list(widget.resource));
        },
      ),
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
                style: const TextStyle(color: muted, fontSize: 22, height: 1.45, fontFamily: 'serif'),
              ),
            ],
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add),
              label: Text(actionLabel),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                textStyle: const TextStyle(fontSize: 18, fontFamily: 'serif', fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourceGrid extends StatelessWidget {
  const _ResourceGrid({required this.resource, required this.items});

  final String resource;
  final List<FamilyItem> items;

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
            if (resource == 'fotos') return _PhotoCard(item: item);
            return LoveTextCard(title: item.title, body: item.subtitle.isEmpty ? 'Sem descrição.' : item.subtitle, footer: _footerFor(resource, item));
          }).toList(),
        );
      },
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.item});

  final FamilyItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: primary.withValues(alpha: .08),
              child: item.title.startsWith('http')
                  ? Image.network(item.title, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.photo, color: primary, size: 48))
                  : const Icon(Icons.photo, color: primary, size: 48),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              item.subtitle.isEmpty ? 'Adicione uma descrição...' : item.subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: muted, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class ResourceDialog extends StatefulWidget {
  const ResourceDialog({super.key, required this.title, required this.resource, required this.onSave});

  final String title;
  final String resource;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  @override
  State<ResourceDialog> createState() => _ResourceDialogState();
}

class _ResourceDialogState extends State<ResourceDialog> {
  final title = TextEditingController();
  final subtitle = TextEditingController();
  final extra = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Novo item em ${widget.title}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Título ou URL')),
            TextField(controller: subtitle, decoration: const InputDecoration(labelText: 'Texto / artista')),
            TextField(controller: extra, decoration: const InputDecoration(labelText: 'Extra')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _save, child: const Text('Salvar')),
      ],
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
      'fotos' => {'url': title.text, 'texto': subtitle.text, 'tipo': extra.text == 'video' ? 'video' : 'imagem'},
      _ => <String, dynamic>{},
    };
    await widget.onSave(data);
    if (mounted) Navigator.pop(context);
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

String _subtitleFor(String resource) {
  return switch (resource) {
    'musicas' => 'Cada música conta uma história nossa. Uma melodia que nos faz sorrir, dançar e reviver momentos especiais do nosso amor.',
    'cartas' => 'Um espaço especial onde guardo todas as minhas declarações de amor para você. Cada carta é um pedacinho do meu coração transformado em palavras.',
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
