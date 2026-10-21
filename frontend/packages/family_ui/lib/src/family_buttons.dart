import 'package:flutter/material.dart';

class FamilyFilledButton extends StatelessWidget {
  const FamilyFilledButton({
    super.key,
    required this.onPressed,
    this.onLongPress,
    this.style,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    required this.child,
    this.icon,
    this.label,
  });

  const FamilyFilledButton.icon({
    super.key,
    required this.onPressed,
    this.onLongPress,
    this.style,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    required this.icon,
    required this.label,
  }) : child = null;

  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final ButtonStyle? style;
  final bool autofocus;
  final Clip clipBehavior;
  final Widget? child;
  final Widget? icon;
  final Widget? label;

  @override
  Widget build(BuildContext context) {
    if (icon != null && label != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        onLongPress: onLongPress,
        style: style,
        autofocus: autofocus,
        clipBehavior: clipBehavior,
        icon: icon!,
        label: label!,
      );
    }
    return FilledButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      style: style,
      autofocus: autofocus,
      clipBehavior: clipBehavior,
      child: child ?? const SizedBox.shrink(),
    );
  }
}

class FamilyOutlinedButton extends StatelessWidget {
  const FamilyOutlinedButton({
    super.key,
    required this.onPressed,
    this.onLongPress,
    this.style,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    required this.child,
    this.icon,
    this.label,
  });

  const FamilyOutlinedButton.icon({
    super.key,
    required this.onPressed,
    this.onLongPress,
    this.style,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    required this.icon,
    required this.label,
  }) : child = null;

  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final ButtonStyle? style;
  final bool autofocus;
  final Clip clipBehavior;
  final Widget? child;
  final Widget? icon;
  final Widget? label;

  @override
  Widget build(BuildContext context) {
    if (icon != null && label != null) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        onLongPress: onLongPress,
        style: style,
        autofocus: autofocus,
        clipBehavior: clipBehavior,
        icon: icon!,
        label: label!,
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      style: style,
      autofocus: autofocus,
      clipBehavior: clipBehavior,
      child: child ?? const SizedBox.shrink(),
    );
  }
}

class FamilyTextButton extends StatelessWidget {
  const FamilyTextButton({
    super.key,
    required this.onPressed,
    this.style,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    required this.child,
    this.icon,
    this.label,
  });

  const FamilyTextButton.icon({
    super.key,
    required this.onPressed,
    this.style,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    required this.icon,
    required this.label,
  }) : child = null;

  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final bool autofocus;
  final Clip clipBehavior;
  final Widget? child;
  final Widget? icon;
  final Widget? label;

  @override
  Widget build(BuildContext context) {
    if (icon != null && label != null) {
      return TextButton.icon(
        onPressed: onPressed,
        style: style,
        autofocus: autofocus,
        clipBehavior: clipBehavior,
        icon: icon!,
        label: label!,
      );
    }
    return TextButton(
      onPressed: onPressed,
      style: style,
      autofocus: autofocus,
      clipBehavior: clipBehavior,
      child: child ?? const SizedBox.shrink(),
    );
  }
}
