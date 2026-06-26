import 'package:flutter/material.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dashboard.dart';
import '../../../data/models.dart';
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
            return _Overview(
              data: snapshot.data!,
              onEditPlan: _editPlan,
            );
          },
        ),
      ],
    );
  }

  void _reload() {
    setState(() => future = repository.overview());
  }

  Future<void> _editPlan(SubscriptionPlan plan) async {
    final updated = await showDialog<SubscriptionPlan>(
      context: context,
      builder: (context) => _PlanEditorDialog(
        plan: plan,
        repository: repository,
      ),
    );
    if (updated == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('Plano atualizado.'))),
    );
    _reload();
  }
}

class _Overview extends StatelessWidget {
  const _Overview({
    required this.data,
    required this.onEditPlan,
  });

  final PlatformOverview data;
  final ValueChanged<SubscriptionPlan> onEditPlan;

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
        AppDashboardSection(
          title: 'Planos de assinatura',
          subtitle: 'Nome, descrição e valor exibidos na landing page.',
          child: _PlansList(
            items: data.plans,
            onEdit: onEditPlan,
          ),
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

class _PlansList extends StatelessWidget {
  const _PlansList({
    required this.items,
    required this.onEdit,
  });

  final List<SubscriptionPlan> items;
  final ValueChanged<SubscriptionPlan> onEdit;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return Text(context.tr('Nenhum plano cadastrado.'));
    return Column(
      children: [
        for (final item in items)
          _ListRow(
            icon: _planIcon(item.interval),
            title: item.name,
            subtitle:
                '${_money(item.priceCents, item.currency)} ${_periodLabel(item.interval)} · ${item.active ? context.tr('Ativo') : context.tr('Inativo')}',
            trailing: item.highlighted ? context.tr('Destaque') : '',
            onTap: () => onEdit(item),
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
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final bool success;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
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
            Text(trailing,
                style: TextStyle(color: palette.muted, fontSize: 11)),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.edit_outlined, size: 18, color: palette.muted),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanEditorDialog extends StatefulWidget {
  const _PlanEditorDialog({
    required this.plan,
    required this.repository,
  });

  final SubscriptionPlan plan;
  final PlatformAdminRepository repository;

  @override
  State<_PlanEditorDialog> createState() => _PlanEditorDialogState();
}

class _PlanEditorDialogState extends State<_PlanEditorDialog> {
  final formKey = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.plan.name);
  late final description = TextEditingController(text: widget.plan.description);
  late final price = TextEditingController(
    text:
        (widget.plan.priceCents / 100).toStringAsFixed(2).replaceAll('.', ','),
  );
  late final currency = TextEditingController(text: widget.plan.currency);
  late final stripePriceId = TextEditingController(
    text: widget.plan.stripePriceId ?? '',
  );
  late final sortOrder = TextEditingController(
    text: widget.plan.sortOrder.toString(),
  );
  late bool active = widget.plan.active;
  late bool highlighted = widget.plan.highlighted;
  bool saving = false;

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    price.dispose();
    currency.dispose();
    stripePriceId.dispose();
    sortOrder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('Editar plano')),
      content: SizedBox(
        width: 560,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: InputDecoration(labelText: context.tr('Nome')),
                  validator: _required,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: description,
                  decoration:
                      InputDecoration(labelText: context.tr('Descrição')),
                  minLines: 2,
                  maxLines: 4,
                  validator: _required,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: price,
                        decoration:
                            InputDecoration(labelText: context.tr('Valor')),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) => _priceCents(value) == null
                            ? 'Valor inválido'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: currency,
                        decoration:
                            InputDecoration(labelText: context.tr('Moeda')),
                        validator: _required,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: stripePriceId,
                  decoration: const InputDecoration(
                    labelText: 'Stripe Price ID',
                    hintText: 'price_...',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: sortOrder,
                  decoration: InputDecoration(labelText: context.tr('Ordem')),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.tr('Ativo')),
                  value: active,
                  onChanged:
                      saving ? null : (value) => setState(() => active = value),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.tr('Destaque na landing')),
                  value: highlighted,
                  onChanged: saving
                      ? null
                      : (value) => setState(() => highlighted = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.of(context).pop(),
          child: Text(context.tr('Cancelar')),
        ),
        FilledButton.icon(
          onPressed: saving ? null : _save,
          icon: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(context.tr('Salvar')),
        ),
      ],
    );
  }

  String? _required(String? value) {
    return value?.trim().isNotEmpty == true ? null : 'Campo obrigatório';
  }

  int? _priceCents(String? value) {
    if (value == null) return null;
    var normalized = value.trim().replaceAll(RegExp(r'[^0-9,.-]'), '').trim();
    if (normalized.contains(',')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    }
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed < 0) return null;
    return (parsed * 100).round();
  }

  Future<void> _save() async {
    if (formKey.currentState?.validate() != true) return;
    final priceCents = _priceCents(price.text);
    if (priceCents == null) return;
    setState(() => saving = true);
    try {
      final updated = await widget.repository.updatePlan(
        widget.plan.interval,
        name: name.text.trim(),
        description: description.text.trim(),
        priceCents: priceCents,
        currency: currency.text.trim().toUpperCase(),
        stripePriceId: stripePriceId.text.trim().isEmpty
            ? null
            : stripePriceId.text.trim(),
        active: active,
        highlighted: highlighted,
        sortOrder: int.tryParse(sortOrder.text.trim()) ?? widget.plan.sortOrder,
      );
      if (mounted) Navigator.of(context).pop(updated);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
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

IconData _planIcon(String interval) {
  return switch (interval) {
    'monthly' => Icons.calendar_month_outlined,
    'semiannual' => Icons.event_repeat_outlined,
    'annual' => Icons.workspace_premium_outlined,
    'lifetime' => Icons.all_inclusive,
    _ => Icons.sell_outlined,
  };
}

String _money(int priceCents, String currency) {
  final value = (priceCents / 100).toStringAsFixed(2).replaceAll('.', ',');
  if (currency.toUpperCase() == 'BRL') return 'R\$ $value';
  return '${currency.toUpperCase()} $value';
}

String _periodLabel(String interval) {
  return switch (interval) {
    'monthly' => '/ mês',
    'semiannual' => '/ semestre',
    'annual' => '/ ano',
    'lifetime' => 'único',
    _ => '',
  };
}

String _date(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
