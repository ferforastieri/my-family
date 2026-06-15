import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LoveBackground extends StatelessWidget {
  const LoveBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  Color.lerp(palette.bgStart, Colors.black, .10)!,
                  palette.bgStart,
                  Color.lerp(palette.bgEnd, palette.primaryDark, .18)!,
                ]
              : [palette.bgStart, palette.bgEnd],
        ),
      ),
      child: child,
    );
  }
}
