import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/flower_garden.dart';
import '../../../core/widgets/love_action_card.dart';
import '../../../core/widgets/love_background.dart';
import '../../../core/config/app_config.dart';
import '../../../data/family_repository.dart';
import '../../../data/models.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.repository,
    required this.onNavigate,
  });

  final FamilyRepository repository;
  final ValueChanged<String> onNavigate;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Timer timer;
  late List<CounterInfo> counters;
  List<HomeEventConfig> events = [];
  List<String> galleryImages = [];
  int? galleryOrder;
  String? loadError;
  Offset? cursorPosition;

  @override
  void initState() {
    super.initState();
    counters = _buildCounters(events);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (events.isEmpty) return;
      setState(() => counters = _buildCounters(events));
    });
    widget.repository.socket.on('home.settings.changed', _onSettingsChanged);
    _loadSettings();
  }

  @override
  void dispose() {
    timer.cancel();
    widget.repository.socket.off('home.settings.changed', _onSettingsChanged);
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final loaded = await widget.repository.getHomeSettings();
      if (!mounted) return;
      setState(() {
        loadError = null;
        events = loaded.events;
        galleryImages = loaded.galleryImages;
        galleryOrder = loaded.galleryOrder;
        counters = _buildCounters(events);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        loadError = error.toString();
        events = [];
        galleryImages = [];
        galleryOrder = null;
        counters = const [];
      });
    }
  }

  void _onSettingsChanged(dynamic data) {
    if (!mounted || data is! Map) return;
    final rows = data['events'];
    if (rows is! List) return;
    final loaded = rows
        .map((row) => HomeEventConfig.fromJson(
              Map<String, dynamic>.from(row as Map),
            ))
        .toList();
    final images = ((data['galleryImages'] as List?) ?? const [])
        .map((image) => image.toString())
        .where((image) => image.trim().isNotEmpty)
        .toList();
    final nextGalleryOrder = (data['galleryOrder'] as num?)?.toInt();
    setState(() {
      events = loaded;
      galleryImages = images;
      galleryOrder = nextGalleryOrder;
      counters = _buildCounters(events);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LoveBackground(
      child: MouseRegion(
        cursor: kIsWeb ? SystemMouseCursors.none : MouseCursor.defer,
        onHover: kIsWeb
            ? (event) => setState(() => cursorPosition = event.localPosition)
            : null,
        onExit: kIsWeb ? (_) => setState(() => cursorPosition = null) : null,
        child: LayoutBuilder(
          builder: (context, viewport) {
            final mobile = viewport.maxWidth < 760;
            final content = ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                  18, mobile ? 16 : 10, 18, mobile ? 0 : 340),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 760;
                        final homeItems = _buildHomeItems(
                          events,
                          galleryImages,
                          galleryOrder,
                        );
                        return Column(
                          children: [
                            if (!mobile) ...[
                              const _HomeTitle(),
                              const SizedBox(height: 14),
                            ],
                            if (loadError != null)
                              _HomeLoadError(
                                message: loadError!,
                                onRetry: _loadSettings,
                              )
                            else if (homeItems.isEmpty)
                              const _HomeCountersLoading()
                            else if (wide)
                              LayoutBuilder(
                                builder: (context, gridConstraints) {
                                  final crossAxisCount =
                                      gridConstraints.maxWidth >= 1040 ? 3 : 2;
                                  return GridView.count(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    crossAxisCount: crossAxisCount,
                                    childAspectRatio: 1.58,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 14,
                                    children: homeItems
                                        .map((item) => item.build(context))
                                        .toList(),
                                  );
                                },
                              )
                            else
                              Column(
                                children: [
                                  for (var i = 0;
                                      i < homeItems.length;
                                      i++) ...[
                                    homeItems[i].build(context),
                                    if (i < homeItems.length - 1)
                                      const SizedBox(height: 14),
                                  ],
                                ],
                              ),
                            if (mobile) ...[
                              const SizedBox(height: 4),
                              const _MobileGardenSection(),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            );

            return Stack(
              children: [
                if (!mobile)
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: _HomeGardenLayer(),
                    ),
                  ),
                if (mobile)
                  Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(18, 10, 18, 0),
                        child: AppPageHeader(
                          title: 'My Family',
                          titleWidget: Semantics(
                            label: 'My Family',
                            image: true,
                            child: Image(
                              image: AssetImage('assets/brand/family-logo.png'),
                              height: 42,
                              alignment: Alignment.centerLeft,
                            ),
                          ),
                          subtitle:
                              'Amor, memórias e pequenos milagres do caminho.',
                          icon: Icons.favorite_outline,
                          showBackButton: false,
                        ),
                      ),
                      Expanded(child: content),
                    ],
                  )
                else
                  content,
                if (kIsWeb && cursorPosition != null)
                  Positioned(
                    left: cursorPosition!.dx - 13,
                    top: cursorPosition!.dy - 13,
                    child: const IgnorePointer(
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CustomPaint(
                          painter: _FlowerCursorPainter(),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MobileGardenSection extends StatelessWidget {
  const _MobileGardenSection();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 240,
      width: double.infinity,
      child: IgnorePointer(
        child: OverflowBox(
          alignment: Alignment.bottomCenter,
          minHeight: 430,
          maxHeight: 430,
          child: SizedBox(
            width: double.infinity,
            height: 430,
            child: FlowerGarden(compactFlowers: true),
          ),
        ),
      ),
    );
  }
}

class _HomeGardenLayer extends StatelessWidget {
  const _HomeGardenLayer();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 760;
        if (!mobile) return const FlowerGarden();

        final visibleHeight = math.min(
          constraints.maxHeight * .50,
          430.0,
        );
        final paintHeight = visibleHeight + 90;
        return Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: double.infinity,
            height: visibleHeight,
            child: OverflowBox(
              alignment: Alignment.bottomCenter,
              minHeight: paintHeight,
              maxHeight: paintHeight,
              child: const SizedBox.expand(
                child: FlowerGarden(compactFlowers: true),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FlowerCursorPainter extends CustomPainter {
  const _FlowerCursorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .48, size.height * .46);
    final petalPaints = [
      Paint()..color = const Color(0xffff73b9),
      Paint()..color = const Color(0xffffb6d4),
    ];
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final petalCenter = center.translate(
        math.cos(angle) * 7,
        math.sin(angle) * 7,
      );
      canvas.save();
      canvas.translate(petalCenter.dx, petalCenter.dy);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 8, height: 13),
        petalPaints[i.isEven ? 0 : 1],
      );
      canvas.restore();
    }
    canvas.drawCircle(center, 5, Paint()..color = const Color(0xffffd166));
    final stem = Path()
      ..moveTo(center.dx + 2, center.dy + 8)
      ..quadraticBezierTo(size.width * .70, size.height * .78, size.width * .90,
          size.height * .92);
    canvas.drawPath(
      stem,
      Paint()
        ..color = const Color(0xff3f7a38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    final leaf = Path()
      ..moveTo(size.width * .70, size.height * .78)
      ..quadraticBezierTo(size.width * .52, size.height * .76, size.width * .58,
          size.height * .62)
      ..quadraticBezierTo(size.width * .74, size.height * .66, size.width * .70,
          size.height * .78)
      ..close();
    canvas.drawPath(
      leaf,
      Paint()..color = const Color(0xff47a35a).withValues(alpha: .9),
    );
  }

  @override
  bool shouldRepaint(covariant _FlowerCursorPainter oldDelegate) => false;
}

class _HomeTitle extends StatelessWidget {
  const _HomeTitle();

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        children: [
          Semantics(
            label: context.tr('My Family'),
            image: true,
            child: Image.asset(
              'assets/brand/family-logo.png',
              height: 96,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('Amor, memórias e pequenos milagres do nosso caminho.'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.muted,
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class CounterInfo {
  const CounterInfo({
    required this.title,
    required this.icon,
    required this.date,
    required this.message,
    required this.elapsed,
    required this.countDirection,
  });

  final String title;
  final String icon;
  final DateTime date;
  final String message;
  final ElapsedTime elapsed;
  final HomeCountDirection countDirection;
}

class ElapsedTime {
  const ElapsedTime({
    required this.years,
    required this.months,
    required this.days,
    required this.totalDays,
    required this.isFuture,
  });

  final int years;
  final int months;
  final int days;
  final int totalDays;
  final bool isFuture;
}

List<CounterInfo> _buildCounters(List<HomeEventConfig> events) {
  return events
      .where((event) => !event.hidden)
      .map(
        (event) => CounterInfo(
          title: event.title,
          icon: event.icon,
          date: event.date,
          message: event.message,
          elapsed: _elapsed(event.date, event.countDirection),
          countDirection: event.countDirection,
        ),
      )
      .toList();
}

List<_HomeLayoutItem> _buildHomeItems(
  List<HomeEventConfig> events,
  List<String> galleryImages,
  int? galleryOrder,
) {
  final items = <_HomeLayoutItem>[];
  final normalizedGalleryOrder =
      (galleryOrder ?? events.length).clamp(0, events.length);
  for (var index = 0; index <= events.length; index++) {
    if (galleryImages.isNotEmpty && index == normalizedGalleryOrder) {
      items.add(_HomeGalleryLayoutItem(galleryImages));
    }
    if (index == events.length) continue;
    final event = events[index];
    if (event.hidden) continue;
    items.add(_HomeCounterLayoutItem(CounterInfo(
      title: event.title,
      icon: event.icon,
      date: event.date,
      message: event.message,
      elapsed: _elapsed(event.date, event.countDirection),
      countDirection: event.countDirection,
    )));
  }
  return items;
}

abstract class _HomeLayoutItem {
  const _HomeLayoutItem();

  Widget build(BuildContext context);
}

class _HomeCounterLayoutItem extends _HomeLayoutItem {
  const _HomeCounterLayoutItem(this.info);

  final CounterInfo info;

  @override
  Widget build(BuildContext context) => CounterCard(info);
}

class _HomeGalleryLayoutItem extends _HomeLayoutItem {
  const _HomeGalleryLayoutItem(this.images);

  final List<String> images;

  @override
  Widget build(BuildContext context) => _HomePhotoCarousel(images: images);
}

class _HomePhotoCarousel extends StatefulWidget {
  const _HomePhotoCarousel({required this.images});

  final List<String> images;

  @override
  State<_HomePhotoCarousel> createState() => _HomePhotoCarouselState();
}

class _HomePhotoCarouselState extends State<_HomePhotoCarousel> {
  late final PageController controller;
  Timer? autoTimer;
  int current = 0;

  @override
  void initState() {
    super.initState();
    controller = PageController(viewportFraction: .78);
    autoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || widget.images.length < 2 || !controller.hasClients) {
        return;
      }
      final next = (current + 1) % widget.images.length;
      controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 620),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    autoTimer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final mobile = MediaQuery.sizeOf(context).width < 760;
    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.hasBoundedHeight;
        final photoHeight = bounded
            ? (constraints.maxHeight - 48).clamp(150.0, 386.0)
            : (mobile ? 292.0 : 386.0);
        return Padding(
          padding:
              EdgeInsets.only(top: mobile ? 4 : 8, bottom: mobile ? 4 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.card.withValues(alpha: .76),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: palette.primary.withValues(alpha: .16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: palette.primary.withValues(alpha: .10),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome,
                            color: palette.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          context.tr('Nossas fotos'),
                          style: TextStyle(
                            color: palette.foreground,
                            fontSize: mobile ? 17 : 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.photo_library_outlined,
                          color: palette.primary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: photoHeight,
                child: PageView.builder(
                  controller: controller,
                  itemCount: widget.images.length,
                  onPageChanged: (index) => setState(() => current = index),
                  itemBuilder: (context, index) {
                    final image = widget.images[index];
                    return AnimatedBuilder(
                      animation: controller,
                      child: _FloatingHomePhoto(
                        url: _homeMediaUrl(image),
                        compact: mobile || bounded,
                      ),
                      builder: (context, child) {
                        var page = current.toDouble();
                        if (controller.hasClients &&
                            controller.position.haveDimensions) {
                          page = controller.page ?? page;
                        }
                        final distance = (page - index).abs().clamp(0.0, 1.0);
                        final scale = 1 - distance * .10;
                        final rotate = (index - page).clamp(-1.0, 1.0) * .045;
                        final y = distance * (mobile ? 22 : 30);
                        return Transform.translate(
                          offset: Offset(0, y),
                          child: Transform.rotate(
                            angle: rotate,
                            child: Transform.scale(
                              scale: scale,
                              child: Opacity(
                                opacity: 1 - distance * .24,
                                child: child,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (widget.images.length > 1 && !bounded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < widget.images.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: i == current ? 18 : 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: i == current
                                ? palette.primary
                                : palette.primary.withValues(alpha: .22),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FloatingHomePhoto extends StatelessWidget {
  const _FloatingHomePhoto({
    required this.url,
    required this.compact,
  });

  final String url;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 14 : 18,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .22),
              blurRadius: compact ? 22 : 34,
              offset: Offset(0, compact ? 14 : 20),
            ),
            BoxShadow(
              color: palette.primary.withValues(alpha: .20),
              blurRadius: compact ? 28 : 42,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return ColoredBox(
                    color: palette.primary.withValues(alpha: .06),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (_, __, ___) => ColoredBox(
                  color: palette.primary.withValues(alpha: .06),
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined, size: 42),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: .10),
                        Colors.transparent,
                        Colors.black.withValues(alpha: .18),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .38),
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _homeMediaUrl(String url) {
  if (url.startsWith('http')) return url;
  return AppConfig.apiUri('/fotos/file?path=${Uri.encodeQueryComponent(url)}')
      .toString();
}

ElapsedTime _elapsed(DateTime date, HomeCountDirection countDirection) {
  final now = DateTime.now();
  final diff = countDirection == HomeCountDirection.backward
      ? date.difference(now)
      : now.difference(date);
  final isFuture = diff.isNegative;
  final days = diff.inDays.abs();
  return ElapsedTime(
    years: days ~/ 365,
    months: ((days % 365) / 30.44).floor(),
    days: (days % 30.44).floor(),
    totalDays: days,
    isFuture: isFuture,
  );
}

class _HomeCountersLoading extends StatelessWidget {
  const _HomeCountersLoading();

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final placeholders = List.generate(
      3,
      (_) => Container(
        height: wide ? 190 : 150,
        decoration: BoxDecoration(
          color: palette.card.withValues(alpha: .54),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.primary.withValues(alpha: .10)),
        ),
      ),
    );
    if (wide) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        childAspectRatio: 1.58,
        crossAxisSpacing: 16,
        mainAxisSpacing: 14,
        children: placeholders,
      );
    }
    return Column(
      children: [
        for (var i = 0; i < placeholders.length; i++) ...[
          placeholders[i],
          if (i < placeholders.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _HomeLoadError extends StatelessWidget {
  const _HomeLoadError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return LovePanel(
      maxWidth: 720,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 42),
          const SizedBox(height: 12),
          Text(
            context.tr('Não foi possível carregar a Home.'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.foreground,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.muted, height: 1.35),
          ),
          const SizedBox(height: 16),
          AppButton(
            onPressed: onRetry,
            label: 'Tentar novamente',
            icon: Icons.refresh,
          ),
        ],
      ),
    );
  }
}

class CounterCard extends StatelessWidget {
  const CounterCard(this.info, {super.key});

  final CounterInfo info;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final colors = [palette.primary, palette.primaryDark];
    final compact = MediaQuery.sizeOf(context).width < 760;
    final values = [
      ('${info.elapsed.years}', context.tr('Anos')),
      ('${info.elapsed.months}', context.tr('Meses')),
      ('${info.elapsed.days}', context.tr('Dias')),
    ];
    final content = Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 16,
        compact ? 10 : 14,
        compact ? 14 : 16,
        compact ? 10 : 14,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: compact ? 38 : 44,
                height: compact ? 38 : 44,
                child: Center(
                  child: Text(info.icon,
                      style: TextStyle(fontSize: compact ? 26 : 30)),
                ),
              ),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.foreground,
                        fontWeight: FontWeight.w900,
                        fontSize: compact ? 16 : 17,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: compact ? 2 : 4),
                    Text(
                      _formatDate(context, info.date),
                      style: TextStyle(
                        color: palette.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 6 : 10),
          Text(
            info.message,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.muted,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: compact ? 7 : 12),
          Row(
            children: values
                .map(
                  (value) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: EdgeInsets.symmetric(vertical: compact ? 5 : 8),
                      decoration: BoxDecoration(
                        color: palette.primary.withValues(alpha: .06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: palette.primary.withValues(alpha: .10),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            value.$1,
                            style: TextStyle(
                              color: palette.foreground,
                              fontWeight: FontWeight.w900,
                              fontSize: compact ? 19 : 22,
                            ),
                          ),
                          Text(
                            value.$2,
                            style: TextStyle(
                              color: palette.muted,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: compact ? 6 : 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: compact ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: .08),
              border: Border.all(color: palette.primary.withValues(alpha: .12)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              context.tr('{prefix} {days} dias', args: {
                'prefix': context.tr(_counterPrefix(info)),
                'days': info.elapsed.totalDays,
              }),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.foreground,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
    return LovePanel(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 7,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
              ),
            ),
            if (compact) content else Expanded(child: content),
          ],
        ),
      ),
    );
  }
}

String _counterPrefix(CounterInfo info) {
  return info.countDirection == HomeCountDirection.backward
      ? 'Faltam'
      : 'Já se passaram';
}

String _formatDate(BuildContext context, DateTime date) {
  return context.tr('{day} de {month} de {year}', args: {
    'day': date.day.toString().padLeft(2, '0'),
    'month': context.l10n.monthName(date.month),
    'year': date.year,
  });
}
