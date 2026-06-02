import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LoveBackground extends StatelessWidget {
  const LoveBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.bgStart, palette.bgEnd],
        ),
      ),
      child: child,
    );
  }
}
