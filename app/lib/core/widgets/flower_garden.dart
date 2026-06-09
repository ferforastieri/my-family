import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FlowerGarden extends StatefulWidget {
  const FlowerGarden({
    super.key,
    this.ambientOnly = false,
    this.compactFlowers = false,
  });

  final bool ambientOnly;
  final bool compactFlowers;

  @override
  State<FlowerGarden> createState() => _FlowerGardenState();
}

class _FlowerGardenState extends State<FlowerGarden>
    with TickerProviderStateMixin {
  late final AnimationController windController;
  late final AnimationController growController;
  final plantedFlowers = <Offset>[];

  @override
  void initState() {
    super.initState();
    windController =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..repeat();
    growController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..forward();
  }

  @override
  void dispose() {
    windController.dispose();
    growController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          if (width <= 0 || height <= 0) return;
          setState(() {
            plantedFlowers.add(Offset(
              (details.localPosition.dx / width).clamp(.04, .96),
              (details.localPosition.dy / height).clamp(.50, .92),
            ));
            if (plantedFlowers.length > 16) {
              plantedFlowers.removeAt(0);
            }
          });
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([windController, growController]),
          builder: (context, _) => CustomPaint(
            painter: _FlowerPainter(
              t: windController.value,
              grow: growController.value,
              plantedFlowers: plantedFlowers,
              palette: Theme.of(context).extension<AppPalette>()!,
              ambientOnly: widget.ambientOnly,
              compactFlowers: widget.compactFlowers,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _FlowerPainter extends CustomPainter {
  const _FlowerPainter({
    required this.t,
    required this.grow,
    required this.plantedFlowers,
    required this.palette,
    required this.ambientOnly,
    required this.compactFlowers,
  });

  final double t;
  final double grow;
  final List<Offset> plantedFlowers;
  final AppPalette palette;
  final bool ambientOnly;
  final bool compactFlowers;

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = math.min(size.width, size.height);
    final scale = shortest / 760;
    final flowerScaleFactor = compactFlowers ? .68 : 1.0;
    final base = Offset(size.width / 2, size.height * .96);
    final flowerGrow = Curves.easeOutCubic.transform(grow);

    _drawAtmosphere(canvas, size);
    _drawDistantHills(canvas, size, scale);
    _drawSoftSparkles(canvas, size, scale);
    _drawButterflies(canvas, size, scale);
    if (ambientOnly) {
      _drawAmbientFlowers(canvas, size, scale);
      return;
    }
    _drawTrees(canvas, size, scale);
    _drawGardenPath(canvas, size, scale);
    _drawGrassBed(canvas, size, scale);
    _drawGrassClumps(canvas, size, scale, backLayer: true);
    _drawGardenFlowers(canvas, size, scale);
    _drawPlantedFlowers(canvas, size, scale);

    final miriamGrow = flowerGrow * _growthSince(DateTime(2025, 4, 15), 365);
    final fernandoGrow = flowerGrow * _growthSince(DateTime(2024, 10, 12), 365);
    final sonGrow = flowerGrow * _growthSince(DateTime(2026, 6, 15), 1825);

    _drawFlower(
      canvas,
      base.translate(-86 * scale, 0),
      scale * .96 * flowerScaleFactor,
      fernandoGrow,
      1,
      -.10,
      .12,
      'F',
    );
    _drawFlower(
      canvas,
      base.translate(86 * scale, 0),
      scale * .96 * flowerScaleFactor,
      miriamGrow,
      1,
      .10,
      .36,
      'M',
    );
    _drawFlower(
      canvas,
      base.translate(0, 34 * scale),
      scale * .62 * flowerScaleFactor,
      sonGrow,
      .92,
      0,
      .72,
      'F',
    );

    _drawSideGrass(canvas, base, scale, flowerGrow);
    _drawGrassClumps(canvas, size, scale, backLayer: false);
  }

  double _growthSince(DateTime start, int adultDays) {
    final now = DateTime.now();
    final days = now.difference(start).inDays;
    if (days <= 0) return .36;
    final progress = (days / adultDays).clamp(0.0, 1.0);
    return .36 + Curves.easeOutCubic.transform(progress) * .64;
  }

  void _drawFlower(Canvas canvas, Offset base, double scale, double grow,
      double opacity, double tilt, double phase, String initial) {
    final sway = math.sin((t + phase) * math.pi * 2) * .055;
    final safeGrow = grow.clamp(.08, 1.0).toDouble();

    canvas.saveLayer(
        null, Paint()..color = Colors.white.withValues(alpha: opacity));
    canvas.translate(base.dx, base.dy);
    canvas.scale(safeGrow, safeGrow);
    canvas.rotate(tilt + sway);
    canvas.translate(0, -280 * scale);
    _drawStem(canvas, scale);
    _drawStemLeaves(canvas, scale);
    _drawFlowerHead(canvas, scale, initial);
    canvas.restore();
  }

  void _drawAtmosphere(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          palette.bgStart.withValues(alpha: .06),
          const Color(0xffffedf5).withValues(alpha: .52),
          const Color(0xffeaf7ef).withValues(alpha: .62),
          palette.bgEnd.withValues(alpha: .72),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);

    final glowCenter = Offset(size.width * .52, size.height * .26);
    canvas.drawCircle(
      glowCenter,
      size.shortestSide * .26,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: .32),
            const Color(0xffffb6d4).withValues(alpha: .12),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(center: glowCenter, radius: size.shortestSide * .28),
        ),
    );
  }

  void _drawDistantHills(Canvas canvas, Size size, double scale) {
    final back = Path()
      ..moveTo(0, size.height * .62)
      ..cubicTo(size.width * .16, size.height * .50, size.width * .28,
          size.height * .64, size.width * .44, size.height * .55)
      ..cubicTo(size.width * .62, size.height * .44, size.width * .77,
          size.height * .61, size.width, size.height * .50)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      back,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xff8bcf9a).withValues(alpha: .18),
            const Color(0xff2f7d56).withValues(alpha: .08),
          ],
        ).createShader(Offset.zero & size),
    );

    final front = Path()
      ..moveTo(0, size.height * .70)
      ..cubicTo(size.width * .18, size.height * .61, size.width * .31,
          size.height * .74, size.width * .50, size.height * .65)
      ..cubicTo(size.width * .68, size.height * .56, size.width * .84,
          size.height * .73, size.width, size.height * .63)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      front,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.primary.withValues(alpha: .12),
            palette.primaryDark.withValues(alpha: .10),
          ],
        ).createShader(Offset.zero & size),
    );

    final mistPaint = Paint()
      ..color = Colors.white.withValues(alpha: .24)
      ..strokeWidth = 2 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 4; i++) {
      final y = size.height * (.54 + i * .055);
      final phase = math.sin(t * math.pi * 2 + i) * 16 * scale;
      canvas.drawArc(
        Rect.fromLTWH(
          -size.width * .08 + phase,
          y,
          size.width * 1.16,
          46 * scale,
        ),
        math.pi * 1.03,
        math.pi * .94,
        false,
        mistPaint..color = Colors.white.withValues(alpha: .16 - i * .025),
      );
    }
  }

  void _drawSoftSparkles(Canvas canvas, Size size, double scale) {
    final paint = Paint()
      ..color = palette.primary.withValues(alpha: .18)
      ..strokeWidth = 1.4 * scale
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 18; i++) {
      final phase = (t + i * .073) % 1;
      final x = (size.width * ((i * 37) % 100) / 100) +
          math.sin(phase * math.pi * 2) * 18 * scale;
      final y = size.height * (.18 + ((i * 19) % 54) / 100) +
          math.cos(phase * math.pi * 2) * 12 * scale;
      final len = (3 + i % 3) * scale;
      paint.color = (i.isEven ? palette.primary : const Color(0xffffb703))
          .withValues(alpha: .12 + math.sin(phase * math.pi * 2).abs() * .12);
      canvas.drawLine(Offset(x - len, y), Offset(x + len, y), paint);
      canvas.drawLine(Offset(x, y - len), Offset(x, y + len), paint);
    }
  }

  void _drawButterflies(Canvas canvas, Size size, double scale) {
    final colors = [
      const Color(0xffff73b9),
      const Color(0xffa855f7),
      const Color(0xffffb703),
    ];
    for (var i = 0; i < 3; i++) {
      final phase = (t + i * .27) % 1;
      final x = size.width * (.22 + i * .25) +
          math.sin(phase * math.pi * 2) * 30 * scale;
      final y = size.height * (.32 + i * .055) +
          math.cos(phase * math.pi * 2 + i) * 18 * scale;
      _drawButterfly(canvas, Offset(x, y), scale * (.42 + i * .06), colors[i],
          phase + i * .13);
    }
  }

  void _drawButterfly(
      Canvas canvas, Offset center, double scale, Color color, double phase) {
    final flap = .72 + math.sin(phase * math.pi * 10).abs() * .38;
    final body = Paint()
      ..color = const Color(0xff5b3a2f).withValues(alpha: .62)
      ..strokeWidth = 2 * scale
      ..strokeCap = StrokeCap.round;
    final wing = Paint()
      ..color = color.withValues(alpha: .38)
      ..style = PaintingStyle.fill;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.sin(phase * math.pi * 2) * .18);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-9 * scale, -2 * scale),
        width: 18 * scale * flap,
        height: 25 * scale,
      ),
      wing,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(9 * scale, -2 * scale),
        width: 18 * scale * flap,
        height: 25 * scale,
      ),
      wing,
    );
    canvas.drawLine(Offset(0, -12 * scale), Offset(0, 13 * scale), body);
    canvas.restore();
  }

  void _drawStem(Canvas canvas, double scale) {
    final stem = RRect.fromRectAndRadius(
      Rect.fromLTWH(-5 * scale, 0, 10 * scale, 340 * scale),
      Radius.circular(10 * scale),
    );
    canvas.drawRRect(
      stem,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.primary,
            palette.primaryDark,
            const Color(0xff2d5a27)
          ],
        ).createShader(stem.outerRect),
    );
  }

  void _drawFlowerHead(Canvas canvas, double scale, String initial) {
    final head = Offset(0, -12 * scale);

    canvas.drawCircle(
      head.translate(0, -8 * scale),
      46 * scale,
      Paint()
        ..color = palette.primary.withValues(alpha: .28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 24 * scale),
    );

    for (var i = 0; i < 12; i++) {
      final angle = i * 30.0;
      _drawRadialPetal(canvas, head, scale, angle, palette.primaryDark,
          const Color(0xffffb6c1));
    }

    _drawRadialPetal(canvas, head.translate(26 * scale, 34 * scale),
        scale * .72, 142, const Color(0xff39c6d6), const Color(0xffa7ffee));

    final white = Paint()..color = Colors.white.withValues(alpha: .96);
    canvas.drawOval(
        Rect.fromCenter(center: head, width: 72 * scale, height: 44 * scale),
        white);
    canvas.drawOval(
      Rect.fromCenter(center: head, width: 43 * scale, height: 24 * scale),
      Paint()
        ..shader =
            LinearGradient(colors: [const Color(0xffffb6c1), palette.primary])
                .createShader(
          Rect.fromCenter(center: head, width: 42 * scale, height: 21 * scale),
        ),
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: 20 * scale,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        head.dx - textPainter.width / 2,
        head.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawRadialPetal(Canvas canvas, Offset center, double scale,
      double degrees, Color dark, Color light) {
    final pulse = 1 + math.sin(t * math.pi * 2 + degrees * .07) * .025;
    final rect = Rect.fromCenter(
        center: Offset(0, -50 * scale), width: 42 * scale, height: 82 * scale);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(degrees * math.pi / 180);
    canvas.scale(pulse, pulse);
    canvas.drawOval(
      rect,
      Paint()
        ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [dark, light]).createShader(rect),
    );
    canvas.drawOval(
      rect,
      Paint()
        ..color = Colors.white.withValues(alpha: .20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * scale,
    );
    canvas.restore();
  }

  void _drawStemLeaves(Canvas canvas, double scale) {
    final leaves = [
      (Offset(4 * scale, 82 * scale), 54.0, false),
      (Offset(-4 * scale, 150 * scale), -62.0, true),
      (Offset(4 * scale, 222 * scale), 56.0, false),
      (Offset(-4 * scale, 282 * scale), -58.0, true),
    ];

    for (final leaf in leaves) {
      _drawLeaf(canvas, leaf.$1, scale, leaf.$2, leaf.$3);
    }
  }

  void _drawLeaf(
      Canvas canvas, Offset origin, double scale, double degrees, bool left) {
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo((left ? -58 : 58) * scale, -32 * scale,
          (left ? -90 : 90) * scale, 8 * scale)
      ..quadraticBezierTo((left ? -48 : 48) * scale, 38 * scale, 0, 0)
      ..close();

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(degrees * math.pi / 180);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(colors: [
          palette.primaryDark.withValues(alpha: .55),
          palette.primary
        ]).createShader(
          Rect.fromLTWH(-100 * scale, -45 * scale, 200 * scale, 90 * scale),
        ),
    );
    canvas.restore();
  }

  void _drawSideGrass(Canvas canvas, Offset base, double scale, double grow) {
    canvas.save();
    canvas.translate(base.dx - 80 * scale, base.dy - 10 * scale);
    canvas.scale(grow, grow);
    for (var i = 0; i < 8; i++) {
      final x = (i - 4) * 16 * scale;
      final h = (52 + i * 5) * scale;
      final path = Path()
        ..moveTo(x, 0)
        ..quadraticBezierTo(
            x - 18 * scale, -h * .55, x + math.sin(i) * 18 * scale, -h);
      canvas.drawPath(
        path,
        Paint()
          ..color = palette.primaryDark.withValues(alpha: .62)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 * scale
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.restore();
  }

  void _drawGrassBed(Canvas canvas, Size size, double scale) {
    final rect =
        Rect.fromLTWH(0, size.height - 132 * scale, size.width, 142 * scale);
    final bed = Path()
      ..moveTo(0, size.height - 92 * scale)
      ..cubicTo(size.width * .20, size.height - 142 * scale, size.width * .40,
          size.height - 62 * scale, size.width * .60, size.height - 116 * scale)
      ..cubicTo(size.width * .78, size.height - 164 * scale, size.width * .90,
          size.height - 82 * scale, size.width, size.height - 112 * scale)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      bed,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xff7bcf7e).withValues(alpha: .20),
            const Color(0xff2d5a27).withValues(alpha: .18),
            palette.primaryDark.withValues(alpha: .20),
          ],
        ).createShader(rect),
    );

    final paint = Paint()
      ..color = palette.primaryDark.withValues(alpha: .28)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 78; i++) {
      final x = size.width * i / 77;
      final h = (26 + (i % 9) * 5) *
          scale *
          (1 + math.sin(t * math.pi * 2 + i) * .07);
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x - 6 * scale, size.height - h)
        ..lineTo(x + 6 * scale, size.height - h * .12)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  void _drawGardenPath(Canvas canvas, Size size, double scale) {
    final path = Path()
      ..moveTo(size.width * .42, size.height)
      ..cubicTo(size.width * .46, size.height * .87, size.width * .48,
          size.height * .78, size.width * .49, size.height * .66)
      ..cubicTo(size.width * .50, size.height * .78, size.width * .56,
          size.height * .89, size.width * .64, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xfffff0d9).withValues(alpha: .26),
            const Color(0xffd9a86c).withValues(alpha: .18),
          ],
        ).createShader(Offset.zero & size),
    );

    final pebblePaint = Paint()..color = Colors.white.withValues(alpha: .20);
    for (var i = 0; i < 18; i++) {
      final y = size.height * (.70 + (i % 9) * .034);
      final lane = i.isEven ? -.026 : .034;
      final x = size.width * (.515 + lane + math.sin(i * 2.1) * .012);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: (7 + i % 4) * scale,
          height: (4 + i % 3) * scale,
        ),
        pebblePaint,
      );
    }
  }

  void _drawTrees(Canvas canvas, Size size, double scale) {
    final ground = size.height - 62 * scale;
    _drawTree(canvas, Offset(size.width * .10, ground), scale * 1.08, -.05);
    _drawTree(
        canvas, Offset(size.width * .88, ground + 4 * scale), scale * .92, .08);
  }

  void _drawTree(Canvas canvas, Offset base, double scale, double lean) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(lean);

    final trunk = RRect.fromRectAndRadius(
      Rect.fromLTWH(-13 * scale, -170 * scale, 26 * scale, 180 * scale),
      Radius.circular(12 * scale),
    );
    canvas.drawRRect(
      trunk,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xff6b3f2a), Color(0xff9a623d)],
        ).createShader(trunk.outerRect),
    );

    final canopy = Path()
      ..moveTo(-112 * scale, -154 * scale)
      ..cubicTo(-104 * scale, -218 * scale, -58 * scale, -272 * scale,
          2 * scale, -278 * scale)
      ..cubicTo(72 * scale, -286 * scale, 118 * scale, -226 * scale,
          110 * scale, -164 * scale)
      ..cubicTo(88 * scale, -110 * scale, 26 * scale, -102 * scale, -18 * scale,
          -112 * scale)
      ..cubicTo(-68 * scale, -102 * scale, -108 * scale, -116 * scale,
          -112 * scale, -154 * scale)
      ..close();
    canvas.drawPath(
      canopy,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.primary.withValues(alpha: .20),
            palette.primaryDark.withValues(alpha: .16),
          ],
        ).createShader(
          Rect.fromLTWH(-120 * scale, -286 * scale, 240 * scale, 190 * scale),
        ),
    );
    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: .10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale;
    for (var i = 0; i < 5; i++) {
      final y = (-235 + i * 24) * scale;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset((i.isEven ? -18 : 16) * scale, y),
          width: (116 - i * 9) * scale,
          height: 34 * scale,
        ),
        math.pi * 1.08,
        math.pi * .82,
        false,
        highlight,
      );
    }

    canvas.restore();
  }

  void _drawGardenFlowers(Canvas canvas, Size size, double scale) {
    final ground = size.height - 80 * scale;
    final colors = [
      (const Color(0xffff69b4), const Color(0xffffb6c1)),
      (const Color(0xffef4444), const Color(0xfffca5a5)),
      (const Color(0xffa855f7), const Color(0xffd8b4fe)),
      (const Color(0xff3b82f6), const Color(0xff93c5fd)),
      (const Color(0xffffb703), const Color(0xffffe08a)),
    ];
    for (var i = 0; i < 42; i++) {
      final row = i % 3;
      final x = size.width * ((i * 29 % 100) / 100);
      final y = ground -
          row * 26 * scale +
          math.sin(i * 1.7) * 10 * scale +
          math.cos(t * math.pi * 2 + i) * 2 * scale;
      final flowerScale = scale * (.22 + row * .05 + (i % 5) * .025);
      final pair = colors[i % colors.length];
      if (i % 4 == 0) {
        _drawTulip(
            canvas, Offset(x, y), flowerScale * 1.2, pair.$1, pair.$2, i * .21);
      } else {
        _drawSmallFlower(
            canvas, Offset(x, y), flowerScale, pair.$1, pair.$2, i * .21);
      }
    }
  }

  void _drawAmbientFlowers(Canvas canvas, Size size, double scale) {
    final colors = [
      (const Color(0xffff69b4), const Color(0xffffc1d8)),
      (const Color(0xffa855f7), const Color(0xffddd6fe)),
      (const Color(0xffffb703), const Color(0xffffe08a)),
      (const Color(0xff3b82f6), const Color(0xffbfdbfe)),
    ];
    final bottom = size.height - 18 * scale;
    for (var i = 0; i < 26; i++) {
      final side = i.isEven ? 0.0 : 1.0;
      final edge = side == 0.0
          ? size.width * (.025 + (i % 7) * .028)
          : size.width * (.975 - (i % 7) * .028);
      final y = bottom -
          (i % 6) * 18 * scale +
          math.sin(t * math.pi * 2 + i) * 3 * scale;
      final pair = colors[i % colors.length];
      final flowerScale = scale * (.18 + (i % 4) * .025);
      if (i % 5 == 0) {
        _drawTulip(canvas, Offset(edge, y), flowerScale * 1.15, pair.$1,
            pair.$2, i * .17);
      } else {
        _drawSmallFlower(
            canvas, Offset(edge, y), flowerScale, pair.$1, pair.$2, i * .17);
      }
    }

    for (var i = 0; i < 18; i++) {
      final x = size.width * (.10 + i * .047);
      final y = size.height - 24 * scale + math.sin(i * 1.8) * 5 * scale;
      final pair = colors[(i + 2) % colors.length];
      _drawSmallFlower(
          canvas, Offset(x, y), scale * .15, pair.$1, pair.$2, i * .23);
    }
  }

  void _drawGrassClumps(
    Canvas canvas,
    Size size,
    double scale, {
    required bool backLayer,
  }) {
    final count = backLayer ? 46 : 34;
    final baseY =
        backLayer ? size.height - 126 * scale : size.height - 34 * scale;
    final alpha = backLayer ? .22 : .42;
    for (var i = 0; i < count; i++) {
      final x = size.width * ((i * 17 % 100) / 100);
      final y = baseY + math.sin(i * 1.31) * 18 * scale;
      final blades = backLayer ? 3 : 5;
      final color = (i.isEven ? const Color(0xff2f7d56) : palette.primaryDark)
          .withValues(alpha: alpha);
      for (var j = 0; j < blades; j++) {
        final h = (backLayer ? 28 : 46) * scale * (.72 + (j % 3) * .18);
        final lean =
            (j - blades / 2) * 9 * scale + math.sin(t * math.pi * 2 + i) * 5;
        final blade = Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(x + lean * .25, y - h * .62, x + lean, y - h);
        canvas.drawPath(
          blade,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = (backLayer ? 2.2 : 3.2) * scale
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  void _drawPlantedFlowers(Canvas canvas, Size size, double scale) {
    final colors = [
      (palette.primaryDark, const Color(0xffffb6c1)),
      (const Color(0xffa855f7), const Color(0xffddd6fe)),
      (const Color(0xffef4444), const Color(0xfffecaca)),
      (const Color(0xff22c55e), const Color(0xffbbf7d0)),
    ];
    for (var i = 0; i < plantedFlowers.length; i++) {
      final point = plantedFlowers[i];
      final pair = colors[i % colors.length];
      final flowerScale = scale * (.38 + (i % 4) * .05);
      _drawSmallFlower(
        canvas,
        Offset(point.dx * size.width, point.dy * size.height),
        flowerScale,
        pair.$1,
        pair.$2,
        i * .31,
      );
    }
  }

  void _drawSmallFlower(Canvas canvas, Offset base, double scale, Color dark,
      Color light, double phase) {
    final sway = math.sin((t + phase) * math.pi * 2) * .10;
    final stemPaint = Paint()
      ..color = const Color(0xff3f7a38).withValues(alpha: .75)
      ..strokeWidth = 4 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final top = base.translate(
        math.sin(phase) * 10 * scale + sway * 18 * scale, -86 * scale);
    canvas.drawLine(base, top, stemPaint);
    _drawLeaf(canvas, base.translate(0, -38 * scale), scale * .34,
        phase.isNegative ? -40 : 42, phase % 2 < 1);

    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final center = top.translate(
          math.cos(angle) * 18 * scale, math.sin(angle) * 18 * scale);
      final rect = Rect.fromCenter(
          center: center, width: 20 * scale, height: 30 * scale);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle + math.pi / 2);
      canvas.translate(-center.dx, -center.dy);
      canvas.drawOval(
        rect,
        Paint()
          ..shader = LinearGradient(colors: [dark, light]).createShader(rect),
      );
      canvas.restore();
    }
    canvas.drawCircle(
        top, 10 * scale, Paint()..color = const Color(0xffffd166));
  }

  void _drawTulip(Canvas canvas, Offset base, double scale, Color dark,
      Color light, double phase) {
    final sway = math.sin((t + phase) * math.pi * 2) * .08;
    final top = base.translate(sway * 18 * scale, -82 * scale);
    canvas.drawLine(
      base,
      top,
      Paint()
        ..color = const Color(0xff3f7a38).withValues(alpha: .72)
        ..strokeWidth = 4 * scale
        ..strokeCap = StrokeCap.round,
    );
    _drawLeaf(canvas, base.translate(0, -34 * scale), scale * .32, 38, false);
    final bloom = Path()
      ..moveTo(top.dx, top.dy + 18 * scale)
      ..cubicTo(top.dx - 28 * scale, top.dy - 6 * scale, top.dx - 18 * scale,
          top.dy - 40 * scale, top.dx, top.dy - 22 * scale)
      ..cubicTo(top.dx + 18 * scale, top.dy - 40 * scale, top.dx + 28 * scale,
          top.dy - 6 * scale, top.dx, top.dy + 18 * scale)
      ..close();
    canvas.drawPath(
      bloom,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [dark, light],
        ).createShader(
          Rect.fromCenter(center: top, width: 64 * scale, height: 70 * scale),
        ),
    );
    canvas.drawPath(
      bloom,
      Paint()
        ..color = Colors.white.withValues(alpha: .18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * scale,
    );
  }

  @override
  bool shouldRepaint(covariant _FlowerPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.grow != grow ||
        oldDelegate.plantedFlowers.length != plantedFlowers.length ||
        oldDelegate.palette != palette ||
        oldDelegate.ambientOnly != ambientOnly ||
        oldDelegate.compactFlowers != compactFlowers;
  }
}
