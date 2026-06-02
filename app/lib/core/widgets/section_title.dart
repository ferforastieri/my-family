import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.size});

  final String text;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).extension<AppTextThemes>()!.display.merge(const TextStyle(
        color: primary,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.1,
      )).copyWith(fontSize: size),
    );
  }
}
