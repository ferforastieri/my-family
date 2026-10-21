import 'package:family_ui/family_ui.dart';
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
    return FamilyButton(
      label: label,
      icon: icon,
      loading: loading,
      onPressed: onPressed,
    );
  }
}
