import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/widgets/app_fixed_header_scroll_view.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/love_action_card.dart';
import '../../../core/widgets/love_background.dart';

class ClientDashboardPage extends StatelessWidget {
  const ClientDashboardPage({super.key, required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final tenant = auth.tenant;
    final user = auth.user;
    return LoveBackground(
      child: AppFixedHeaderScrollView(
        maxWidth: 820,
        header: AppPageHeader(
          title: 'Configurações da família',
          subtitle: tenant?.name ?? 'Família selecionada',
          icon: Icons.tune_outlined,
          actionLabel: 'Trocar família',
          actionIcon: Icons.switch_account_outlined,
          onAction: () => context.go('/familias'),
          showBackButton: false,
        ),
        children: [
          LovePanel(
            child: Row(
              children: [
                Image.asset(
                  'assets/brand/family-logo.png',
                  width: 52,
                  height: 52,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenant?.name ?? context.tr('Minha família'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${context.tr(_statusLabel(tenant?.status))} · ${context.tr(_roleLabel(user?.role))}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          LoveActionCard(
            title: 'Assinatura e publicação',
            description: 'Plano, endereço público e disponibilidade do site.',
            icon: Icons.workspace_premium_outlined,
            onTap: () => context.go('/billing'),
          ),
          const SizedBox(height: 12),
          LoveActionCard(
            title: 'Perfil',
            description: 'Nome, foto e segurança da sua conta.',
            icon: Icons.person_outline,
            onTap: () => context.go('/perfil'),
          ),
          if (user?.isAdmin == true) ...[
            const SizedBox(height: 12),
            LoveActionCard(
              title: 'Administração da família',
              description: 'Usuários, jogos, notificações e Home.',
              icon: Icons.admin_panel_settings_outlined,
              onTap: () => context.go('/admin/familia'),
            ),
          ],
        ],
      ),
    );
  }
}

String _statusLabel(String? status) {
  return switch (status) {
    'active' => 'Ativa',
    'pending_payment' => 'Pendente',
    'past_due' => 'Em atraso',
    'suspended' => 'Suspensa',
    'canceled' => 'Cancelada',
    _ => 'Rascunho',
  };
}

String _roleLabel(String? role) {
  return switch (role) {
    'owner' => 'Proprietário',
    'admin' => 'Administrador',
    _ => 'Membro',
  };
}
