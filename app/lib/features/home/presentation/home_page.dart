import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/flower_garden.dart';
import '../../../core/widgets/love_action_card.dart';
import '../../../core/widgets/love_background.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onNavigate});

  final ValueChanged<String> onNavigate;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Timer timer;
  late List<CounterInfo> counters;
  Offset? cursorPosition;

  @override
  void initState() {
    super.initState();
    counters = _buildCounters();
    timer = Timer.periodic(const Duration(seconds: 1),
        (_) => setState(() => counters = _buildCounters()));
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
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
        child: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(
                child: FlowerGarden(),
              ),
            ),
            RefreshIndicator(
              onRefresh: () async =>
                  setState(() => counters = _buildCounters()),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 112),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        children: [
                          const _HomeTitle(),
                          const SizedBox(height: 18),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final wide = constraints.maxWidth >= 760;
                              return GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: wide ? 3 : 1,
                                childAspectRatio: wide ? 1.58 : 1.42,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                children: counters
                                    .map((counter) => CounterCard(counter))
                                    .toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                          LoveActionCard(
                            title: 'Nossa Jornada',
                            description:
                                'Escreva e guarde os capítulos da caminhada da família.',
                            icon: Icons.menu_book_outlined,
                            onTap: () => widget.onNavigate('/nossa-historia'),
                            maxWidth: 720,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
        ),
      ),
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
    final text = Theme.of(context).extension<AppTextThemes>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        children: [
          Text(
            'Nossa Família',
            textAlign: TextAlign.center,
            style: text.display.merge(
              TextStyle(
                color: palette.primary,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Amor, memórias e pequenos milagres do nosso caminho.',
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
    required this.colors,
  });

  final String title;
  final String icon;
  final DateTime date;
  final String message;
  final ElapsedTime elapsed;
  final List<Color> colors;
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

List<CounterInfo> _buildCounters() {
  return [
    CounterInfo(
      title: 'Começamos a Namorar',
      icon: '💕',
      date: DateTime(2024, 10, 12),
      message: 'Desde o primeiro olhar, sabia que você era especial',
      elapsed: _elapsed(DateTime(2024, 10, 12)),
      colors: const [primary, primaryDark],
    ),
    CounterInfo(
      title: 'Nosso Casamento',
      icon: '💍',
      date: DateTime(2025, 4, 15),
      message: 'O dia mais feliz da minha vida ao seu lado',
      elapsed: _elapsed(DateTime(2025, 4, 15)),
      colors: const [Color(0xffff73b9), Color(0xffdf5198)],
    ),
    CounterInfo(
      title: 'Nascimento do Fernando',
      icon: '👶',
      date: DateTime(2026, 6, 15),
      message: 'Nosso maior presente de amor chegando',
      elapsed: _elapsed(DateTime(2026, 6, 15)),
      colors: const [Color(0xffc084fc), Color(0xff9333ea)],
    ),
  ];
}

ElapsedTime _elapsed(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
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

class CounterCard extends StatelessWidget {
  const CounterCard(this.info, {super.key});

  final CounterInfo info;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final values = [
      ('${info.elapsed.years}', 'Anos'),
      ('${info.elapsed.months}', 'Meses'),
      ('${info.elapsed.days}', 'Dias'),
    ];
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
                gradient: LinearGradient(colors: info.colors),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                            child: Text(info.icon,
                                style: const TextStyle(fontSize: 30)),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                                  fontSize: 17,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(info.date),
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
                    const SizedBox(height: 10),
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
                    const SizedBox(height: 12),
                    Row(
                      children: values
                          .map(
                            (value) => Expanded(
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: palette.primary.withValues(alpha: .06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        palette.primary.withValues(alpha: .10),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      value.$1,
                                      style: TextStyle(
                                        color: palette.foreground,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 22,
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
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: info.colors.last.withValues(alpha: .08),
                        border: Border.all(
                            color: info.colors.last.withValues(alpha: .12)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${info.elapsed.isFuture ? 'Faltam' : 'Já se passaram'} ${info.elapsed.totalDays} dias',
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro'
  ];
  return '${date.day.toString().padLeft(2, '0')} de ${months[date.month - 1]} de ${date.year}';
}
