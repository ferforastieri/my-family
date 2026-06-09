import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

class AppHeaderActionsScope extends InheritedWidget {
  const AppHeaderActionsScope({
    super.key,
    required this.onNotifications,
    required this.onTheme,
    required super.child,
  });

  final VoidCallback onNotifications;
  final VoidCallback onTheme;

  static AppHeaderActionsScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppHeaderActionsScope>();
  }

  @override
  bool updateShouldNotify(AppHeaderActionsScope oldWidget) {
    return onNotifications != oldWidget.onNotifications ||
        onTheme != oldWidget.onTheme;
  }
}

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
        final mobileActions =
            desktop ? null : AppHeaderActionsScope.maybeOf(context);
        final titleRow = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!desktop) ...[
              _HeaderIconButton(
                onPressed: onBack ?? () => _defaultBack(context),
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Voltar',
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.foreground,
                            fontSize: desktop ? 24 : 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (!desktop) ...[
                        const SizedBox(width: 8),
                        Icon(icon, color: primary, size: 22),
                      ],
                    ],
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
            if (!desktop) ...[
              const SizedBox(width: 10),
              if (mobileActions != null) ...[
                _HeaderIconButton(
                  onPressed: mobileActions.onNotifications,
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Notificações',
                ),
                const SizedBox(width: 6),
                _HeaderIconButton(
                  onPressed: mobileActions.onTheme,
                  icon: const Icon(Icons.palette_outlined),
                  tooltip: 'Cor e tema',
                ),
              ],
            ],
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

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
  });

  final VoidCallback onPressed;
  final Widget icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: primary.withValues(alpha: .10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: primary.withValues(alpha: .16)),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: IconTheme(
            data: IconThemeData(color: palette.foreground, size: 21),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(child: icon),
            ),
          ),
        ),
      ),
    );
  }
}
