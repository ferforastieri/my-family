import 'package:flutter/material.dart';

/// A true shimmer effect (moving highlight), using the project palette.
class FamilyShimmer extends StatefulWidget {
  const FamilyShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1400),
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  @override
  State<FamilyShimmer> createState() => _FamilyShimmerState();
}

class _FamilyShimmerState extends State<FamilyShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = widget.baseColor ??
        Color.lerp(scheme.surface, scheme.primary, .16) ??
        scheme.surfaceContainerHighest;
    final highlight = widget.highlightColor ??
        Color.lerp(scheme.surface, scheme.primary, .34) ??
        scheme.primaryContainer;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(-1.6 + t * 3.2, 0),
            end: Alignment(-.6 + t * 3.2, 0),
            colors: [base, highlight, base],
            stops: const [0, .5, 1],
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

class FamilySkeletonBox extends StatelessWidget {
  const FamilySkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 10,
    this.baseColor,
    this.highlightColor,
  });

  final double? width;
  final double height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = baseColor ??
        Color.lerp(scheme.surface, scheme.primary, .16) ??
        scheme.surfaceContainerHighest;
    return FamilyShimmer(
      baseColor: base,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class FamilySkeletonCircle extends StatelessWidget {
  const FamilySkeletonCircle({
    super.key,
    required this.size,
    this.baseColor,
    this.highlightColor,
  });

  final double size;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    return FamilySkeletonBox(
      width: size,
      height: size,
      borderRadius: size / 2,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
  }
}

class FamilySkeletonLine extends StatelessWidget {
  const FamilySkeletonLine({
    super.key,
    this.width,
    this.height = 12,
    this.baseColor,
    this.highlightColor,
  });

  final double? width;
  final double height;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    return FamilySkeletonBox(
      width: width,
      height: height,
      borderRadius: 999,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
  }
}

class FamilySkeletonCard extends StatelessWidget {
  const FamilySkeletonCard({
    super.key,
    this.height = 148,
    this.radius = 18,
    this.padding = const EdgeInsets.all(18),
  });

  final double height;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .55)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FamilySkeletonLine(width: 132, height: 16),
          SizedBox(height: 12),
          FamilySkeletonLine(width: 220),
          SizedBox(height: 8),
          FamilySkeletonLine(width: 176),
          Spacer(),
          FamilySkeletonLine(width: 96, height: 10),
        ],
      ),
    );
  }
}
