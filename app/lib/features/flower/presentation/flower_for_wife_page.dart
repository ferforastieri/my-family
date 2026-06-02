import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/love_background.dart';
import '../../../core/widgets/section_title.dart';

class FlowerForWifePage extends StatefulWidget {
  const FlowerForWifePage({super.key});

  @override
  State<FlowerForWifePage> createState() => _FlowerForWifePageState();
}

class _FlowerForWifePageState extends State<FlowerForWifePage> with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoveBackground(
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) => CustomPaint(
                painter: _FlowerPainter(
                  t: controller.value,
                  palette: Theme.of(context).extension<AppPalette>()!,
                ),
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(24, 34, 24, 32),
            children: [
              const SectionTitle('Uma Flor para Minha Esposa', size: 44)
                  .animate()
                  .fadeIn(duration: 650.ms)
                  .scale(begin: const Offset(.94, .94), end: const Offset(1, 1), curve: Curves.easeOutBack),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlowerPainter extends CustomPainter {
  const _FlowerPainter({required this.t, required this.palette});

  final double t;
  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = math.min(size.width, size.height);
    final scale = shortest / 760;
    final base = Offset(size.width / 2, size.height * .92);
    final grow = Curves.easeOutCubic.transform((t * 1.5).clamp(0, 1));

    _drawNight(canvas, size);
    _drawFireflies(canvas, size, scale);
    _drawGrassBed(canvas, size, scale);

    _drawFlower(canvas, base.translate(0, 0), scale, grow, 1, 0, 0);
    _drawFlower(canvas, base.translate(-135 * scale, 12 * scale), scale * .74, grow, .78, -.24, .35);
    _drawFlower(canvas, base.translate(132 * scale, 16 * scale), scale * .68, grow, .70, .28, .72);

    _drawLongLeaf(canvas, base, scale, grow);
    _drawSideGrass(canvas, base, scale, grow);
  }

  void _drawFlower(Canvas canvas, Offset base, double scale, double grow, double opacity, double tilt, double phase) {
    final sway = math.sin((t + phase) * math.pi * 2) * .055;
    final localGrow = Curves.easeOutCubic.transform(((t - phase * .18) * 1.8).clamp(0, 1));

    canvas.saveLayer(null, Paint()..color = Colors.white.withValues(alpha: opacity));
    canvas.translate(base.dx, base.dy);
    canvas.scale(grow * localGrow, grow * localGrow);
    canvas.rotate(tilt + sway);
    canvas.translate(0, -280 * scale);
    _drawStem(canvas, scale);
    _drawStemLeaves(canvas, scale);
    _drawFlowerHead(canvas, scale);
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

  void _drawFireflies(Canvas canvas, Size size, double scale) {
    final paint = Paint()
      ..color = palette.primary.withValues(alpha: .36)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * scale);
    for (var i = 0; i < 18; i++) {
      final phase = (t + i * .073) % 1;
      final x = (size.width * ((i * 37) % 100) / 100) + math.sin(phase * math.pi * 2) * 18 * scale;
      final y = size.height * (.25 + ((i * 19) % 55) / 100) + math.cos(phase * math.pi * 2) * 12 * scale;
      final radius = (1.8 + (i % 4) * .45) * scale;
      canvas.drawCircle(Offset(x, y), radius, paint);
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
          colors: [palette.primary, palette.primaryDark, const Color(0xff2d5a27)],
        ).createShader(stem.outerRect),
    );
  }

  void _drawFlowerHead(Canvas canvas, double scale) {
    final head = Offset(0, -12 * scale);

    canvas.drawCircle(
      head.translate(0, -8 * scale),
      46 * scale,
      Paint()
        ..color = palette.primary.withValues(alpha: .28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 24 * scale),
    );

    for (final angle in [-70.0, -42.0, -16.0, 16.0, 42.0, 70.0]) {
      _drawPetal(canvas, head, scale, angle, palette.primaryDark, const Color(0xffffb6c1));
    }

    _drawPetal(canvas, head.translate(4 * scale, 10 * scale), scale * .82, 132, const Color(0xff39c6d6), const Color(0xffa7ffee));

    final white = Paint()..color = Colors.white.withValues(alpha: .96);
    canvas.drawOval(Rect.fromCenter(center: head.translate(0, 8 * scale), width: 70 * scale, height: 34 * scale), white);
    canvas.drawOval(
      Rect.fromCenter(center: head.translate(0, 7 * scale), width: 42 * scale, height: 21 * scale),
      Paint()
        ..shader = LinearGradient(colors: [const Color(0xffffb6c1), palette.primary]).createShader(
          Rect.fromCenter(center: head, width: 42 * scale, height: 21 * scale),
        ),
    );
  }

  void _drawPetal(Canvas canvas, Offset center, double scale, double degrees, Color dark, Color light) {
    final rect = Rect.fromCenter(center: Offset.zero, width: 58 * scale, height: 88 * scale);
    final pulse = 1 + math.sin(t * math.pi * 2 + degrees) * .025;
    final path = Path()
      ..moveTo(0, 0)
      ..cubicTo(36 * scale, -34 * scale, 30 * scale, -86 * scale, 0, -96 * scale)
      ..cubicTo(-30 * scale, -86 * scale, -36 * scale, -34 * scale, 0, 0)
      ..close();

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(degrees * math.pi / 180);
    canvas.scale(pulse, pulse);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [dark, light]).createShader(rect)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: .22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * scale,
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

  void _drawLeaf(Canvas canvas, Offset origin, double scale, double degrees, bool left) {
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo((left ? -58 : 58) * scale, -32 * scale, (left ? -90 : 90) * scale, 8 * scale)
      ..quadraticBezierTo((left ? -48 : 48) * scale, 38 * scale, 0, 0)
      ..close();

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(degrees * math.pi / 180);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(colors: [palette.primaryDark.withValues(alpha: .55), palette.primary]).createShader(
          Rect.fromLTWH(-100 * scale, -45 * scale, 200 * scale, 90 * scale),
        ),
    );
    canvas.restore();
  }

  void _drawLongLeaf(Canvas canvas, Offset base, double scale, double grow) {
    final sway = math.sin(t * math.pi * 2 + 1.3) * .05;
    canvas.save();
    canvas.translate(base.dx - 58 * scale, base.dy - 52 * scale);
    canvas.scale(grow, grow);
    canvas.rotate(-.88 + sway);

    final stemPaint = Paint()
      ..color = palette.primaryDark
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 9 * scale;
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(30 * scale, -90 * scale, 88 * scale, -126 * scale);
    canvas.drawPath(path, stemPaint);

    _drawLeaf(canvas, Offset(76 * scale, -116 * scale), scale * .85, -18, false);
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
        ..quadraticBezierTo(x - 18 * scale, -h * .55, x + math.sin(i) * 18 * scale, -h);
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
    final rect = Rect.fromLTWH(0, size.height - 86 * scale, size.width, 96 * scale);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xff2d5a27).withValues(alpha: .12), palette.primaryDark.withValues(alpha: .16)],
        ).createShader(rect),
    );

    final paint = Paint()
      ..color = palette.primaryDark.withValues(alpha: .28)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 58; i++) {
      final x = size.width * i / 57;
      final h = (26 + (i % 9) * 5) * scale * (1 + math.sin(t * math.pi * 2 + i) * .07);
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x - 6 * scale, size.height - h)
        ..lineTo(x + 6 * scale, size.height - h * .12)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FlowerPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.palette != palette;
  }
}
