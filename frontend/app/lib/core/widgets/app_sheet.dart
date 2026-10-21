import 'package:family_ui/family_ui.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => AppSheet(child: builder(sheetContext)),
  );
}

class AppSheet extends StatelessWidget {
  const AppSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, 0, 8, bottomInset),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .92,
          ),
          decoration: BoxDecoration(
            color: palette.card.withValues(alpha: .98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border.all(color: palette.primary.withValues(alpha: .18)),
            boxShadow: [
              BoxShadow(
                color: palette.primary.withValues(alpha: .18),
                blurRadius: 28,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: .28),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Flexible(
                child: Theme(
                  data: theme.copyWith(
                    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppSheetHeader extends StatelessWidget {
  const AppSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: palette.primary),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: palette.foreground,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(color: palette.muted, height: 1.35),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class AppSheetActions extends StatelessWidget {
  const AppSheetActions({
    super.key,
    required this.onCancel,
    required this.onSave,
    this.saveLabel = 'Salvar',
    this.loading = false,
  });

  final VoidCallback? onCancel;
  final VoidCallback? onSave;
  final String saveLabel;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FamilyOutlinedButton(
            onPressed: loading ? null : onCancel,
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FamilyButton(
            onPressed: onSave,
            label: saveLabel,
            icon: Icons.check,
            loading: loading,
          ),
        ),
      ],
    );
  }
}

