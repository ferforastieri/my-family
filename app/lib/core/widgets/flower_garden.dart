import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FlowerGarden extends StatefulWidget {
  const FlowerGarden({super.key});

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
  });

  final double t;
  final double grow;
  final List<Offset> plantedFlowers;
  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = math.min(size.width, size.height);
    final scale = shortest / 760;
    final base = Offset(size.width / 2, size.height * .92);
    final flowerGrow = Curves.easeOutCubic.transform(grow);

    _drawNight(canvas, size);
    _drawSoftSparkles(canvas, size, scale);
    _drawTrees(canvas, size, scale);
    _drawGrassBed(canvas, size, scale);
    _drawGardenFlowers(canvas, size, scale);
    _drawPlantedFlowers(canvas, size, scale);

    final miriamGrow = flowerGrow * _growthSince(DateTime(2025, 4, 15), 365);
    final fernandoGrow = flowerGrow * _growthSince(DateTime(2024, 10, 12), 365);
    final sonGrow = flowerGrow * _growthSince(DateTime(2026, 6, 15), 1825);

    _drawFlower(
      canvas,
      base.translate(-86 * scale, 0),
      scale * .96,
      fernandoGrow,
      1,
      -.10,
      .12,
      'F',
    );
    _drawFlower(
      canvas,
      base.translate(86 * scale, 0),
      scale * .96,
      miriamGrow,
      1,
      .10,
      .36,
      'M',
    );
    _drawFlower(
      canvas,
      base.translate(0, 34 * scale),
      scale * .62,
      sonGrow,
      .92,
      0,
      .72,
      'F',
    );

    _drawSideGrass(canvas, base, scale, flowerGrow);
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

  void _drawNight(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          palette.bgStart.withValues(alpha: .10),
          palette.primary.withValues(alpha: .08),
          palette.bgEnd.withValues(alpha: .50),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _drawSoftSparkles(Canvas canvas, Size size, double scale) {
    final paint = Paint()
      ..color = palette.primary.withValues(alpha: .18)
      ..strokeWidth = 1.4 * scale
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 10; i++) {
      final phase = (t + i * .073) % 1;
      final x = (size.width * ((i * 37) % 100) / 100) +
          math.sin(phase * math.pi * 2) * 18 * scale;
      final y = size.height * (.25 + ((i * 19) % 55) / 100) +
          math.cos(phase * math.pi * 2) * 12 * scale;
      final len = (3 + i % 3) * scale;
      canvas.drawLine(Offset(x - len, y), Offset(x + len, y), paint);
      canvas.drawLine(Offset(x, y - len), Offset(x, y + len), paint);
    }
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
        Rect.fromLTWH(0, size.height - 86 * scale, size.width, 96 * scale);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xff2d5a27).withValues(alpha: .12),
            palette.primaryDark.withValues(alpha: .16)
          ],
        ).createShader(rect),
    );

    final paint = Paint()
      ..color = palette.primaryDark.withValues(alpha: .28)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 58; i++) {
      final x = size.width * i / 57;
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
    for (var i = 0; i < 22; i++) {
      final x = size.width * (.04 + i * .044);
      final y = ground + math.sin(i * 1.7) * 12 * scale;
      final flowerScale = scale * (.30 + (i % 5) * .035);
      final pair = colors[i % colors.length];
      _drawSmallFlower(
          canvas, Offset(x, y), flowerScale, pair.$1, pair.$2, i * .21);
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

  @override
  bool shouldRepaint(covariant _FlowerPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.grow != grow ||
        oldDelegate.plantedFlowers.length != plantedFlowers.length ||
        oldDelegate.palette != palette;
  }
}
