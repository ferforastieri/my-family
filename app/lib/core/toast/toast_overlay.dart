import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'toast_controller.dart';

class ToastOverlay extends StatelessWidget {
  const ToastOverlay(
      {super.key, required this.controller, required this.child});

  final ToastController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final toast = controller.current;
            return AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                alignment: toast == null
                    ? const Alignment(0, -1.25)
                    : Alignment.topCenter,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: toast == null ? 0 : 1,
                  child: SafeArea(
                    child: Padding(
                      padding:
                          const EdgeInsets.only(top: 14, left: 16, right: 16),
                      child: toast == null
                          ? const SizedBox.shrink()
                          : _ToastCard(toast: toast, controller: controller),
                    ),
                  ),
                ),
              );
          },
        ),
      ],
    );
  }
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({required this.toast, required this.controller});

  final AppToast toast;
  final ToastController controller;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = switch (toast.kind) {
      ToastKind.success => palette.primary,
      ToastKind.error => Theme.of(context).colorScheme.error,
      ToastKind.info => palette.primary,
    };
    final icon = switch (toast.kind) {
      ToastKind.success => Icons.check_circle_outline,
      ToastKind.error => Icons.error_outline,
      ToastKind.info => Icons.info_outline,
    };

    return Dismissible(
      key: ValueKey(toast.id),
      direction: DismissDirection.horizontal,
      onDismissed: (_) => controller.clear(),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Material(
          color: palette.card,
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? .16 : .08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: .34)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    toast.message,
                    style: TextStyle(
                      color: palette.foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
