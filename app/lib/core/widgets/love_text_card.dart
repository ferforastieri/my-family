import 'package:flutter/material.dart';
import 'package:mix/mix.dart' hide primary;

import '../theme/app_colors.dart';
import '../theme/app_mix_styles.dart';
import '../theme/app_theme.dart';

class LoveTextCard extends StatelessWidget {
  const LoveTextCard({
    super.key,
    required this.title,
    required this.body,
    this.footer,
    this.onTap,
  });

  final String title;
  final String body;
  final String? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = DecoratedBox(
      decoration: BoxDecoration(
        border: loveCardBorder,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x1aff69b4), blurRadius: 12, offset: Offset(0, 3))],
      ),
      child: Box(
        style: loveCardStyle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).extension<AppTextThemes>()!.display.merge(TextStyle(
                color: primary,
                fontWeight: FontWeight.w800,
                fontSize: 24,
              )),
            ),
            const SizedBox(height: 14),
            Text(body, style: const TextStyle(color: muted, fontSize: 17, height: 1.5)),
            if (footer != null) ...[
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: Text(footer!, style: TextStyle(color: primary, fontStyle: FontStyle.italic)),
              ),
            ],
          ],
        ),
      ),
    );

    if (onTap == null) return card;
    return InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap, child: card);
  }
}
