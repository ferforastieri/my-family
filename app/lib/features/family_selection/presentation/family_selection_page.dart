import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_fixed_header_scroll_view.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/love_action_card.dart';
import '../../../core/widgets/love_background.dart';
import '../../../data/models.dart';

class FamilySelectionPage extends StatefulWidget {
  const FamilySelectionPage({
    super.key,
    required this.auth,
    required this.toast,
    this.nextPath,
  });

  final AuthController auth;
  final ToastController toast;
  final String? nextPath;

  @override
  State<FamilySelectionPage> createState() => _FamilySelectionPageState();
}

class _FamilySelectionPageState extends State<FamilySelectionPage> {
  String? loadingSlug;

  Future<void> _select(TenantMembershipOption option) async {
    if (loadingSlug != null) return;
    setState(() => loadingSlug = option.tenant.slug);
    try {
      await widget.auth.selectTenant(option.tenant.slug);
      widget.toast.backendSuccess(widget.auth.takeMessage());
      if (!mounted) return;
      final tenant = widget.auth.tenant;
      context.go(
        tenant?.isActive == true ? widget.nextPath ?? '/' : '/billing',
      );
    } catch (error) {
      widget.toast.error(authErrorMessage(error));
    } finally {
      if (mounted) setState(() => loadingSlug = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberships = widget.auth.memberships;
    final palette = Theme.of(context).extension<AppPalette>()!;
    return LoveBackground(
      child: AppFixedHeaderScrollView(
        maxWidth: 760,
        header: AppPageHeader(
          title: 'Escolher família',
          subtitle: 'Entre no espaço que você quer acessar agora.',
          icon: Icons.diversity_1_outlined,
          actionLabel: 'Sair',
          actionIcon: Icons.logout,
          onAction: widget.auth.signOut,
          showBackButton: false,
        ),
        children: [
          if (memberships.isEmpty)
            LovePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.tr('Nenhuma família encontrada.'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.tr('Entre com outra conta ou crie uma família.'),
                    style: TextStyle(color: palette.muted, height: 1.35),
                  ),
                  const SizedBox(height: 18),
                  AppButton(
                    onPressed: widget.auth.signOut,
                    label: 'Sair',
                    icon: Icons.logout,
                  ),
                ],
              ),
            )
          else
            ...memberships.map((option) {
              final loading = loadingSlug == option.tenant.slug;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: LoveActionCard(
                  title: option.tenant.name,
                  description:
                      '${context.l10n.statusLabel(option.tenant.status)} · ${context.tr(option.role)}',
                  icon: Icons.family_restroom_outlined,
                  onTap: loading ? () {} : () => _select(option),
                  trailing: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
              );
            }),
        ],
      ),
    );
  }
}
