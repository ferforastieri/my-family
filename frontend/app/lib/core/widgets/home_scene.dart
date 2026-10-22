import 'package:family_ui/family_ui.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum HomeScene { flowers, aurora, ocean, night }

extension HomeSceneInfo on HomeScene {
  String get label {
    switch (this) {
      case HomeScene.flowers:
        return 'Flores';
      case HomeScene.aurora:
        return 'Aurora';
      case HomeScene.ocean:
        return 'Oceano';
      case HomeScene.night:
        return 'Noite';
    }
  }

  String get description {
    switch (this) {
      case HomeScene.flowers:
        return 'Tulipas ao sol';
      case HomeScene.aurora:
        return 'Céu do norte';
      case HomeScene.ocean:
        return 'Mar ao entardecer';
      case HomeScene.night:
        return 'Estrelas e montanhas';
    }
  }

  String get asset {
    switch (this) {
      case HomeScene.flowers:
        return 'assets/scenes/flowers.jpg';
      case HomeScene.aurora:
        return 'assets/scenes/aurora.jpg';
      case HomeScene.ocean:
        return 'assets/scenes/ocean.jpg';
      case HomeScene.night:
        return 'assets/scenes/night.jpg';
    }
  }

  IconData get icon {
    switch (this) {
      case HomeScene.flowers:
        return FamilyIcons.localFloristOutlined;
      case HomeScene.aurora:
        return FamilyIcons.autoAwesomeOutlined;
      case HomeScene.ocean:
        return FamilyIcons.wavesOutlined;
      case HomeScene.night:
        return FamilyIcons.nightlightOutlined;
    }
  }
}

class HomeSceneBackground extends StatefulWidget {
  const HomeSceneBackground({
    super.key,
    required this.scene,
    required this.child,
  });

  final HomeScene scene;
  final Widget child;

  @override
  State<HomeSceneBackground> createState() => _HomeSceneBackgroundState();
}

class _HomeSceneBackgroundState extends State<HomeSceneBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 26),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 850),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) => Stack(
            fit: StackFit.expand,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild
            ],
          ),
          child: _ScenePhoto(
            key: ValueKey(widget.scene),
            scene: widget.scene,
            animation: _controller,
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          Colors.black.withValues(alpha: .62),
                          Colors.black.withValues(alpha: .42),
                          Colors.black.withValues(alpha: .72),
                        ]
                      : [
                          palette.bgStart.withValues(alpha: .84),
                          palette.bgStart.withValues(alpha: .52),
                          palette.bgStart.withValues(alpha: .88),
                        ],
                  stops: const [0, .48, 1],
                ),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _ScenePhoto extends StatelessWidget {
  const _ScenePhoto({
    super.key,
    required this.scene,
    required this.animation,
  });

  final HomeScene scene;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutSine,
    );
    return ClipRect(
      child: AnimatedBuilder(
        animation: curved,
        builder: (context, child) {
          final t = curved.value;
          return Transform.scale(
            scale: 1.04 + t * .075,
            child: Transform.translate(
              offset: Offset(6 - t * 12, -4 + t * 8),
              child: child,
            ),
          );
        },
        child: RepaintBoundary(
          child: Image.asset(
            scene.asset,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace) => const ColoredBox(
              color: Color(0xfffefbf3),
            ),
          ),
        ),
      ),
    );
  }
}
