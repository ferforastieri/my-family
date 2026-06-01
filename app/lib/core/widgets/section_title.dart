import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.size});

  final String text;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: primary,
        fontFamily: 'serif',
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.1,
      ).copyWith(fontSize: size),
    );
  }
}

