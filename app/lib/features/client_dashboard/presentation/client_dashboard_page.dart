import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/widgets/app_dashboard.dart';

class ClientDashboardPage extends StatelessWidget {
  const ClientDashboardPage({super.key, required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final tenant = auth.tenant;
    final user = auth.user;
    return AppDashboardPage(
      title: tenant?.name ?? 'Painel da família',
      subtitle: 'Gerencie sua conta, publicação e conteúdo.',
      leading: Image.asset(
        'assets/brand/family-logo.png',
        width: 40,
        height: 40,
      ),
      children: [
        Text(
          'Olá, ${user?.name?.split(' ').first ?? 'bem-vindo'}',
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          'Este é o centro de controle da sua família.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        AppMetricGrid(
          children: [
            AppMetricCard(
              label: 'Assinatura',
              value: _statusLabel(tenant?.status),
              icon: Icons.workspace_premium_outlined,
              caption: 'Situação atual da conta',
            ),
            AppMetricCard(
              label: 'Publicação',
              value: tenant?.isPublished == true ? 'Online' : 'Privado',
              icon: tenant?.isPublished == true
                  ? Icons.public
                  : Icons.public_off_outlined,
              caption: tenant?.slug ?? '',
            ),
            AppMetricCard(
              label: 'Seu perfil',
              value: _roleLabel(user?.role),
              icon: Icons.manage_accounts_outlined,
              caption: user?.email,
            ),
            AppMetricCard(
              label: 'Áreas liberadas',
              value: user?.isAdmin == true
                  ? 'Todas'
                  : '${user?.access.length ?? 0}',
              icon: Icons.grid_view_outlined,
              caption: 'Recursos acessíveis',
            ),
          ],
        ),
        const SizedBox(height: 20),
        AppDashboardSection(
          title: 'Acessos rápidos',
          subtitle: 'Escolha a área que deseja gerenciar.',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final actions = [
                const AppDashboardAction(
                  title: 'Abrir site da família',
                  description: 'Veja a experiência e os conteúdos da família.',
                  icon: Icons.favorite_outline,
                  route: '/',
                ),
                const AppDashboardAction(
                  title: 'Assinatura e publicação',
                  description: 'Plano, endereço e disponibilidade pública.',
                  icon: Icons.payments_outlined,
                  route: '/billing',
                ),
                const AppDashboardAction(
                  title: 'Perfil',
                  description: 'Nome, foto e segurança da conta.',
                  icon: Icons.person_outline,
                  route: '/perfil',
                ),
                if (user?.isAdmin == true)
                  const AppDashboardAction(
                    title: 'Administrar família',
                    description: 'Usuários, jogos, notificações e página.',
                    icon: Icons.admin_panel_settings_outlined,
                    route: '/cliente/admin',
                  ),
              ];
              final wide = constraints.maxWidth >= 760;
              return GridView.count(
                crossAxisCount: wide ? 2 : 1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: wide ? 3.6 : 3.2,
                children: actions,
              );
            },
          ),
        ),
      ],
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
