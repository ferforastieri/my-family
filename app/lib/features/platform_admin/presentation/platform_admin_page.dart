import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dashboard.dart';
import '../data/platform_admin_repository.dart';

class PlatformAdminPage extends StatefulWidget {
  const PlatformAdminPage({super.key, required this.auth});

  final AuthController auth;

  @override
  State<PlatformAdminPage> createState() => _PlatformAdminPageState();
}

class _PlatformAdminPageState extends State<PlatformAdminPage> {
  late final PlatformAdminRepository repository =
      PlatformAdminRepository(widget.auth);
  late Future<PlatformOverview> future = repository.overview();

  @override
  void initState() {
    super.initState();
    unawaited(widget.auth.trackEvent('navigation', path: '/plataforma'));
  }

  @override
  Widget build(BuildContext context) {
    return AppDashboardPage(
      title: 'Administração da plataforma',
      subtitle: 'Usuários, famílias, assinaturas e auditoria.',
      leading: const Icon(Icons.shield_outlined, size: 34),
      actions: [
        IconButton(
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
          tooltip: context.tr('Atualizar'),
        ),
        IconButton(
          onPressed: () => context.go('/painel'),
          icon: const Icon(Icons.family_restroom_outlined),
          tooltip: context.tr('Painel da família'),
        ),
      ],
      children: [
        FutureBuilder<PlatformOverview>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 420,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError || snapshot.data == null) {
              return _ErrorState(
                message: snapshot.error.toString(),
                onRetry: _reload,
              );
            }
            return _Overview(data: snapshot.data!);
          },
        ),
      ],
    );
  }

  void _reload() {
    setState(() => future = repository.overview());
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.data});

  final PlatformOverview data;

  @override
  Widget build(BuildContext context) {
    final metrics = data.metrics;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppMetricGrid(
          children: [
            AppMetricCard(
              label: 'Usuários',
              value: '${metrics.totalUsers}',
              caption: context.tr('+{count} nos últimos 30 dias',
                  args: {'count': metrics.newUsers30d}),
              icon: Icons.people_alt_outlined,
            ),
            AppMetricCard(
              label: 'Famílias',
              value: '${metrics.totalTenants}',
              caption: context
                  .tr('{count} ativas', args: {'count': metrics.activeTenants}),
              icon: Icons.family_restroom_outlined,
            ),
            AppMetricCard(
              label: 'Assinaturas ativas',
              value: '${metrics.activeSubscriptions}',
              caption: context.tr('{count} aguardando pagamento',
                  args: {'count': metrics.pendingTenants}),
              icon: Icons.credit_score_outlined,
            ),
            AppMetricCard(
              label: 'Eventos monitorados',
              value: '${metrics.auditEvents24h}',
              caption: 'Nas últimas 24 horas',
              icon: Icons.monitor_heart_outlined,
            ),
          ],
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 840;
            final tenants = AppDashboardSection(
              title: 'Famílias recentes',
              subtitle: 'Últimos cadastros da plataforma.',
              child: _TenantList(items: data.recentTenants),
            );
            final audit = AppDashboardSection(
              title: 'Atividade recente',
              subtitle: 'Ações relevantes registradas pelo backend.',
              child: _AuditList(items: data.recentAudit),
            );
            if (!wide) {
              return Column(
                children: [tenants, const SizedBox(height: 20), audit],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: tenants),
                const SizedBox(width: 20),
                Expanded(child: audit),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TenantList extends StatelessWidget {
  const _TenantList({required this.items});

  final List<PlatformTenantSummary> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return Text(context.tr('Nenhuma família cadastrada.'));
    return Column(
      children: [
        for (final item in items)
          _ListRow(
            icon: item.isPublished ? Icons.public : Icons.public_off_outlined,
            title: item.name,
            subtitle:
                '${item.slug} · ${context.tr(_tenantStatus(item.status))}',
            trailing: _date(item.createdAt),
          ),
      ],
    );
  }
}

class _AuditList extends StatelessWidget {
  const _AuditList({required this.items});

  final List<PlatformAuditEntry> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return Text(context.tr('Nenhuma atividade registrada.'));
    return Column(
      children: [
        for (final item in items)
          _ListRow(
            icon:
                item.success ? Icons.check_circle_outline : Icons.error_outline,
            title: item.actorEmail ?? context.tr('Sistema'),
            subtitle: item.action,
            trailing: _date(item.createdAt),
            success: item.success,
          ),
      ],
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.success = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, color: success ? palette.primary : Colors.redAccent),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: palette.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(trailing, style: TextStyle(color: palette.muted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(context.tr('Tentar novamente')),
          ),
        ],
      ),
    );
  }
}

String _tenantStatus(String status) {
  return switch (status) {
    'active' => 'Ativa',
    'pending_payment' => 'Pagamento pendente',
    'past_due' => 'Em atraso',
    'suspended' => 'Suspensa',
    'canceled' => 'Cancelada',
    _ => 'Rascunho',
  };
}

String _date(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
