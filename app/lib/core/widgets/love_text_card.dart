import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'love_action_card.dart';

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
    final palette = Theme.of(context).extension<AppPalette>()!;
    final card = LovePanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).extension<AppTextThemes>()!.display.merge(
                  const TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
          ),
          const SizedBox(height: 14),
          Text(body,
              style:
                  TextStyle(color: palette.muted, fontSize: 17, height: 1.5)),
          if (footer != null) ...[
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: Text(footer!,
                  style: TextStyle(
                    color: palette.primary,
                    fontStyle: FontStyle.italic,
                  )),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
          borderRadius: BorderRadius.circular(16), onTap: onTap, child: card),
    );
  }
}
