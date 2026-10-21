import 'package:flutter/material.dart';

import 'family_skeleton.dart';

enum FamilyButtonVariant { primary, secondary, ghost, danger }

class FamilyButton extends StatelessWidget {
  const FamilyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.variant = FamilyButtonVariant.primary,
    this.expand = false,
    this.height = 48,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final FamilyButtonVariant variant;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = switch (variant) {
      FamilyButtonVariant.primary || FamilyButtonVariant.danger => Colors.white,
      _ => scheme.primary,
    };
    final background = switch (variant) {
      FamilyButtonVariant.primary => scheme.primary,
      FamilyButtonVariant.danger => scheme.error,
      _ => Colors.transparent,
    };
    final border = switch (variant) {
      FamilyButtonVariant.secondary => BorderSide(color: scheme.primary),
      FamilyButtonVariant.ghost => BorderSide.none,
      _ => BorderSide.none,
    };
    final child = loading
        ? SizedBox(
            width: 58,
            child: FamilyShimmer(
              baseColor: foreground.withValues(alpha: .24),
              highlightColor: foreground.withValues(alpha: .62),
              child: Container(
                height: 11,
                decoration: BoxDecoration(
                  color: foreground.withValues(alpha: .24),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 19),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    final Widget action;
    switch (variant) {
      case FamilyButtonVariant.primary:
      case FamilyButtonVariant.danger:
        action = FilledButton(
          onPressed: loading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            shape: shape,
          ),
          child: child,
        );
      case FamilyButtonVariant.secondary:
        action = OutlinedButton(
          onPressed: loading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: foreground,
            side: border,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            shape: shape,
          ),
          child: child,
        );
      case FamilyButtonVariant.ghost:
        action = TextButton(
          onPressed: loading ? null : onPressed,
          style: TextButton.styleFrom(foregroundColor: foreground),
          child: child,
        );
    }
    return SizedBox(
      height: height,
      width: expand ? double.infinity : null,
      child: action,
    );
  }
}
