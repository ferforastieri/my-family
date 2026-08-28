import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2))
        : Text(label);
    if (icon == null) {
      return FilledButton(onPressed: loading ? null : onPressed, child: child);
    }
    return FilledButton.icon(
      onPressed: loading ? null : onPressed,
      icon: Icon(icon),
      label: child,
    );
  }
}
