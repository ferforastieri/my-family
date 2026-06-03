import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.onBack,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final desktop = MediaQuery.sizeOf(context).width >= 860;
    final action = onAction == null || actionLabel == null
        ? null
        : AppButton(
            onPressed: onAction,
            label: actionLabel!,
            icon: actionIcon,
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final titleRow = Row(
          children: [
            if (!desktop) ...[
              IconButton(
                onPressed: onBack ?? () => _defaultBack(context),
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Voltar',
                color: palette.foreground,
              ),
              const SizedBox(width: 2),
              Icon(icon, color: primary, size: 22),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.foreground,
                      fontSize: desktop ? 24 : 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (!desktop && subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: palette.muted, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );

        final content = action == null
            ? titleRow
            : compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      titleRow,
                      const SizedBox(height: 10),
                      action,
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: titleRow),
                      const SizedBox(width: 12),
                      action,
                    ],
                  );

        return Container(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: palette.border.withValues(alpha: .75)),
            ),
          ),
          child: content,
        );
      },
    );
  }

  void _defaultBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/');
  }
}
