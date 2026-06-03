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
            return IgnorePointer(
              child: AnimatedAlign(
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
                          : _ToastCard(toast: toast),
                    ),
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
  const _ToastCard({required this.toast});

  final AppToast toast;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final color = switch (toast.kind) {
      ToastKind.success => const Color(0xff16a34a),
      ToastKind.error => Theme.of(context).colorScheme.error,
      ToastKind.info => palette.primary,
    };
    final icon = switch (toast.kind) {
      ToastKind.success => Icons.check_circle_outline,
      ToastKind.error => Icons.error_outline,
      ToastKind.info => Icons.info_outline,
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Material(
        color: palette.card,
        elevation: 12,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: .32)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  toast.message,
                  style: TextStyle(
                      color: palette.foreground, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
