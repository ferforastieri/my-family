import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

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
    final card = Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: primary,
                fontFamily: 'serif',
                fontWeight: FontWeight.w800,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 14),
            Text(body, style: const TextStyle(color: muted, fontSize: 17, height: 1.5)),
            if (footer != null) ...[
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: Text(footer!, style: const TextStyle(color: primary, fontStyle: FontStyle.italic)),
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

