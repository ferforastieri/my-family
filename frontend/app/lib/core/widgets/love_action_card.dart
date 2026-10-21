import 'package:family_ui/family_ui.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LovePanel extends StatelessWidget {
  const LovePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.maxWidth,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return FamilyCard(
      padding: padding,
      maxWidth: maxWidth,
      color: palette.card.withValues(alpha: .92),
      borderColor: palette.border,
      child: child,
    );
  }
}

class LoveActionCard extends StatelessWidget {
  const LoveActionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.trailing,
    this.maxWidth,
    this.padding = const EdgeInsets.all(20),
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailing;
  final double? maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final card = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: LovePanel(
          padding: padding,
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: palette.primary, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.foreground,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: palette.muted, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing ?? Icon(Icons.chevron_right, color: palette.primary),
            ],
          ),
        ),
      ),
    );
    if (maxWidth == null) return card;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth!),
      child: card,
    );
  }
}
