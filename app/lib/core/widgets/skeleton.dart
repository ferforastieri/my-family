import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'love_background.dart';

class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 18,
    this.borderRadius = 12,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: .45, end: .9).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut)),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: primary.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

class PageSkeleton extends StatelessWidget {
  const PageSkeleton({super.key, this.cards = 6});

  final int cards;

  @override
  Widget build(BuildContext context) {
    return LoveBackground(
      child: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const Center(child: SkeletonBox(width: 320, height: 44, borderRadius: 18)),
          const SizedBox(height: 32),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900
                      ? 3
                      : constraints.maxWidth >= 620
                          ? 2
                          : 1;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: columns,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 32,
                    mainAxisSpacing: 32,
                    children: List.generate(cards, (_) => const SkeletonCard()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonBox(width: 180, height: 24),
            SizedBox(height: 18),
            SkeletonBox(height: 16),
            SizedBox(height: 10),
            SkeletonBox(width: 220, height: 16),
            Spacer(),
            Align(alignment: Alignment.centerRight, child: SkeletonBox(width: 110, height: 14)),
          ],
        ),
      ),
    );
  }
}

