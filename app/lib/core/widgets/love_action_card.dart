import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

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
    final panel = Material(
      color: Colors.white.withValues(alpha: .92),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primary.withValues(alpha: .18)),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: .10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
    );
    if (maxWidth == null) return panel;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth!),
      child: panel,
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
    final card = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: LovePanel(
          padding: padding,
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: primary, size: 30),
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
                      style: const TextStyle(
                        color: foreground,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: muted, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing ?? const Icon(Icons.chevron_right, color: primary),
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
