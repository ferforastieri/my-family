import 'package:flutter/material.dart';

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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).extension<AppTextThemes>()!.display.merge(
                  TextStyle(
                    color: palette.foreground,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: palette.muted, fontSize: 16, height: 1.42),
          ),
          if (footer != null) ...[
            const SizedBox(height: 12),
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
