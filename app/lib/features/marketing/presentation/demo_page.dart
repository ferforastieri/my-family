import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/love_background.dart';
import '../domain/marketing_copy.dart';

class DemoPage extends StatefulWidget {
  const DemoPage({super.key, required this.locale});

  final MarketingLocale locale;

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  late Future<Map<String, dynamic>> demo = _load();

  @override
  Widget build(BuildContext context) {
    final t = marketingCopy[widget.locale]!;
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LoveBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: palette.bgStart.withValues(alpha: .94),
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                onPressed: () => context.go('/?locale=${widget.locale.code}'),
                icon: const Icon(Icons.arrow_back),
                tooltip: t.back,
              ),
              title: Text(t.brand,
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              actions: [
                TextButton(
                  onPressed: () =>
                      context.go('/signup?locale=${widget.locale.code}'),
                  child: Text(t.primary),
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: palette.primary.withValues(alpha: .12),
                child: Text(
                  t.demoBadge,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.primaryDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: FutureBuilder<Map<String, dynamic>>(
                future: demo,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const SizedBox(
                      height: 420,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError || snapshot.data == null) {
                    return SizedBox(
                      height: 420,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cloud_off_outlined, size: 46),
                            const SizedBox(height: 14),
                            Text(snapshot.error?.toString() ??
                                'Demonstração indisponível.'),
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              onPressed: () => setState(() => demo = _load()),
                              icon: const Icon(Icons.refresh),
                              label: Text(t.tryAgain),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return _DemoContent(
                    data: snapshot.data!,
                    locale: widget.locale,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _load() async {
    final response = await http
        .get(AppConfig.apiUri('/public/sites/demo'))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Demonstração indisponível.');
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final data = payload['data'];
    return data is Map
        ? Map<String, dynamic>.from(data)
        : Map<String, dynamic>.from(payload);
  }
}

class _DemoContent extends StatelessWidget {
  const _DemoContent({required this.data, required this.locale});

  final Map<String, dynamic> data;
  final MarketingLocale locale;

  @override
  Widget build(BuildContext context) {
    final t = marketingCopy[locale]!;
    final tenant = _map(data['tenant']);
    final home = _map(data['home']);
    final events =
        _list(home['events']).where((row) => row['hidden'] != true).toList();
    final photos = _list(data['photos']);
    final songs = _list(data['songs']);
    final journey = _list(data['journey']);
    final name = tenant['name']?.toString() ?? t.brand;
    final slug = tenant['slug']?.toString() ?? 'demo';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 62, 18, 90),
          child: Column(
            children: [
              Text('♥  ${t.eyebrow.toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 46, height: 1.05, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 60),
              if (events.isNotEmpty) ...[
                _SectionTitle(title: t.events),
                const SizedBox(height: 20),
                _ResponsiveCards(
                  children: events
                      .map((event) => _InfoCard(
                            icon: event['icon']?.toString() ?? '♥',
                            title: event['title']?.toString() ?? '',
                            body: event['message']?.toString() ?? '',
                          ))
                      .toList(),
                ),
                const SizedBox(height: 70),
              ],
              if (photos.isNotEmpty) ...[
                _SectionTitle(title: t.memories),
                const SizedBox(height: 20),
                _ResponsiveCards(
                  children: photos
                      .take(12)
                      .map((photo) => _PhotoCard(
                            title: photo['album']?.toString() ?? t.memories,
                            body: photo['texto']?.toString(),
                            url: photo['url'] == null
                                ? null
                                : _mediaUri(slug, photo['url'].toString())
                                    .toString(),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 70),
              ],
              if (songs.isNotEmpty) ...[
                _SectionTitle(title: t.features[1].$2),
                const SizedBox(height: 20),
                _ResponsiveCards(
                  children: songs
                      .take(8)
                      .map((song) => _InfoCard(
                            icon: '♫',
                            title: song['titulo']?.toString() ?? '',
                            body: [song['artista'], song['descricao']]
                                .where((value) =>
                                    value != null &&
                                    value.toString().isNotEmpty)
                                .join(' · '),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 70),
              ],
              if (journey.isNotEmpty) ...[
                _SectionTitle(title: t.features[3].$2),
                const SizedBox(height: 20),
                _ResponsiveCards(
                  children: journey
                      .take(8)
                      .map((item) => _InfoCard(
                            icon: '🌿',
                            title: item['titulo']?.toString() ?? '',
                            body: item['conteudo']?.toString() ?? '',
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 80),
              Text(
                t.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 32, height: 1.1, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () => context.go('/signup?locale=${locale.code}'),
                icon: const Icon(Icons.favorite_outline),
                label: Text(t.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
      );
}

class _ResponsiveCards extends StatelessWidget {
  const _ResponsiveCards({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 900
          ? 3
          : constraints.maxWidth >= 580
              ? 2
              : 1;
      final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: children
            .map((child) => SizedBox(width: width, child: child))
            .toList(),
      );
    });
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(
      {required this.icon, required this.title, required this.body});
  final String icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Container(
      constraints: const BoxConstraints(minHeight: 170),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: palette.card,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 27)),
          const SizedBox(height: 15),
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(body, style: TextStyle(color: palette.muted, height: 1.5)),
          ],
        ],
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard(
      {required this.title, required this.body, required this.url});
  final String title;
  final String? body;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
            color: palette.card, border: Border.all(color: palette.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: url == null
                  ? ColoredBox(color: palette.primary.withValues(alpha: .08))
                  : Image.network(
                      url!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => ColoredBox(
                        color: palette.primary.withValues(alpha: .08),
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  if (body?.isNotEmpty == true) ...[
                    const SizedBox(height: 7),
                    Text(body!, style: TextStyle(color: palette.muted)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<Map<String, dynamic>> _list(dynamic value) => value is List
    ? value
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList()
    : <Map<String, dynamic>>[];

Uri _mediaUri(String slug, String path) => AppConfig.apiUri(
      '/public/sites/${Uri.encodeComponent(slug)}/media',
    ).replace(queryParameters: {'path': path});
