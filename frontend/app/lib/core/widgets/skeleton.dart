import 'package:family_ui/family_ui.dart';
import 'package:flutter/material.dart';

import 'love_background.dart';

class SkeletonBox extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return FamilySkeletonBox(
      width: width,
      height: height,
      borderRadius: borderRadius,
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
        padding: const EdgeInsets.all(28),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      SkeletonBox(width: 44, height: 44, borderRadius: 999),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox(width: 240, height: 24),
                            SizedBox(height: 8),
                            SkeletonBox(width: 360, height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const SkeletonBox(height: 52, borderRadius: 14),
                  const SizedBox(height: 22),
                  LayoutBuilder(
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
                        crossAxisSpacing: 18,
                        mainAxisSpacing: 18,
                        children: List.generate(
                          cards,
                          (_) => const SkeletonCard(),
                        ),
                      );
                    },
                  ),
                ],
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
    return const FamilySkeletonCard(height: 220);
  }
}


class ListPageSkeleton extends StatelessWidget {
  const ListPageSkeleton({super.key, this.rows = 5});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemCount: rows,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const Row(
        children: [
          SkeletonBox(width: 42, height: 42, borderRadius: 999),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 180, height: 14),
                SizedBox(height: 8),
                SkeletonBox(width: 250, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
