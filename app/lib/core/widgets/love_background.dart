import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class LoveBackground extends StatelessWidget {
  const LoveBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgStart, bgEnd],
        ),
      ),
      child: child,
    );
  }
}

