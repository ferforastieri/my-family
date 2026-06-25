import 'package:flutter/material.dart';

import '../i18n/app_localizations.dart';
import '../theme/app_theme.dart';

class AppDropdownAction<T> {
  const AppDropdownAction({
    required this.value,
    required this.label,
    required this.icon,
    this.destructive = false,
  });

  final T value;
  final String label;
  final IconData icon;
  final bool destructive;
}

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.actions,
    required this.onSelected,
    required this.child,
    this.tooltip,
  });

  final List<AppDropdownAction<T>> actions;
  final ValueChanged<T> onSelected;
  final Widget child;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return PopupMenuButton<T>(
      tooltip: tooltip == null ? null : context.tr(tooltip!),
      offset: const Offset(0, 12),
      color: palette.card,
      elevation: 14,
      shadowColor: palette.primary.withValues(alpha: .20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: palette.border),
      ),
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final action in actions)
          PopupMenuItem<T>(
            value: action.value,
            padding: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                dense: true,
                minLeadingWidth: 24,
                leading: Icon(
                  action.icon,
                  color:
                      action.destructive ? Colors.redAccent : palette.primary,
                ),
                title: Text(
                  context.tr(action.label),
                  style: TextStyle(
                    color: action.destructive
                        ? Colors.redAccent
                        : palette.foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
      ],
      child: child,
    );
  }
}
