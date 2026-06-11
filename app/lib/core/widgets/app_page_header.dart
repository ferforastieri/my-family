import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import 'app_button.dart';

class AppHeaderActionsScope extends InheritedWidget {
  const AppHeaderActionsScope({
    super.key,
    required this.onNotifications,
    required this.onTheme,
    required this.notificationCount,
    required super.child,
  });

  final VoidCallback onNotifications;
  final VoidCallback onTheme;
  final int notificationCount;

  static AppHeaderActionsScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppHeaderActionsScope>();
  }

  @override
  bool updateShouldNotify(AppHeaderActionsScope oldWidget) {
    return onNotifications != oldWidget.onNotifications ||
        onTheme != oldWidget.onTheme ||
        notificationCount != oldWidget.notificationCount;
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
    this.inlineAction = false,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final VoidCallback? onBack;
  final bool inlineAction;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final desktop = MediaQuery.sizeOf(context).width >= 860;
    final action = onAction == null || actionLabel == null
        ? null
        : inlineAction
            ? AppHeaderIconButton(
                onPressed: onAction!,
                icon: Icon(actionIcon ?? Icons.more_horiz),
                tooltip: actionLabel!,
              )
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
              AppHeaderIconButton(
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
                        Icon(icon, color: palette.primary, size: 22),
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
                AppHeaderIconButton(
                  onPressed: mobileActions.onNotifications,
                  icon: _HeaderBadge(
                    count: mobileActions.notificationCount,
                    child: const Icon(Icons.notifications_outlined),
                  ),
                  tooltip: 'Notificações',
                ),
                const SizedBox(width: 6),
                AppHeaderIconButton(
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
            : compact && !inlineAction
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

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -8,
          top: -8,
          child: _BadgeLabel(count: count),
        ),
      ],
    );
  }
}

class _BadgeLabel extends StatelessWidget {
  const _BadgeLabel({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : count.toString();
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: palette.primary,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class AppHeaderIconButton extends StatelessWidget {
  const AppHeaderIconButton({
    super.key,
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
        color: palette.primary.withValues(alpha: .10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: palette.primary.withValues(alpha: .16)),
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
