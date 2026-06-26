import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/config/app_config.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_fixed_header_scroll_view.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/love_action_card.dart';
import '../../../core/widgets/love_background.dart';
import '../../../data/models.dart';

class BillingPage extends StatefulWidget {
  const BillingPage({
    super.key,
    required this.auth,
    required this.toast,
    this.initialPlanInterval,
  });

  final AuthController auth;
  final ToastController toast;
  final String? initialPlanInterval;

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  late final name = TextEditingController(text: widget.auth.tenant?.name);
  late final slug = TextEditingController(text: widget.auth.tenant?.slug);
  late Future<List<SubscriptionPlan>> plansFuture;
  String locale = 'pt-BR';
  String? selectedPlanInterval;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    locale = widget.auth.tenant?.defaultLocale ?? 'pt-BR';
    selectedPlanInterval = widget.initialPlanInterval;
    plansFuture = _loadPlans();
  }

  @override
  void dispose() {
    name.dispose();
    slug.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => loading = true);
    try {
      await action();
      widget.toast.backendSuccess(widget.auth.takeMessage());
    } catch (error) {
      widget.toast.error(authErrorMessage(error));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<List<SubscriptionPlan>> _loadPlans() async {
    final plans = await widget.auth.subscriptionPlans();
    if (selectedPlanInterval == null) {
      for (final plan in plans) {
        if (plan.highlighted) {
          selectedPlanInterval = plan.interval;
          break;
        }
      }
      selectedPlanInterval ??= plans.isEmpty ? null : plans.first.interval;
    }
    return plans;
  }

  Future<void> _checkout() => _run(() async {
        final errorMessage = context.tr('Não foi possível abrir o pagamento.');
        final planInterval = selectedPlanInterval;
        if (planInterval == null) {
          throw StateError(context.tr('Escolha um plano para continuar.'));
        }
        final url = await widget.auth.createCheckout(
          planInterval: planInterval,
        );
        if (url.isEmpty ||
            !await launchUrl(Uri.parse(url),
                mode: LaunchMode.externalApplication)) {
          throw StateError(errorMessage);
        }
      });

  Future<void> _portal() => _run(() async {
        final errorMessage =
            context.tr('Não foi possível abrir o portal da assinatura.');
        final url = await widget.auth.createBillingPortal();
        if (url.isEmpty ||
            !await launchUrl(Uri.parse(url),
                mode: LaunchMode.externalApplication)) {
          throw StateError(errorMessage);
        }
      });

  Future<void> _refresh() => _run(() async {
        await widget.auth.refreshTenant();
        final tenant = widget.auth.tenant;
        if (tenant != null) {
          name.text = tenant.name;
          slug.text = tenant.slug;
          locale = tenant.defaultLocale;
        }
      });

  Future<void> _save() => _run(() => widget.auth.updateTenant(
        name: name.text,
        slug: slug.text,
        locale: locale,
      ));

  @override
  Widget build(BuildContext context) {
    final tenant = widget.auth.tenant;
    final palette = Theme.of(context).extension<AppPalette>()!;
    return LoveBackground(
      child: AppFixedHeaderScrollView(
        header: const AppPageHeader(
          title: 'Meu espaço',
          subtitle: 'Assinatura, endereço e publicação.',
          icon: Icons.workspace_premium_outlined,
        ),
        children: [
          LovePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: palette.primary.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.favorite, color: palette.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tenant?.name ?? context.tr('Minha família'),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w900)),
                      Text(context.l10n.statusLabel(tenant?.status),
                          style: TextStyle(
                              color: tenant?.isActive == true
                                  ? Colors.green.shade700
                                  : palette.primaryDark,
                              fontWeight: FontWeight.w800)),
                    ],
                  )),
                ]),
                const SizedBox(height: 18),
                if (tenant?.isActive != true) ...[
                  Text(
                    context.tr('Escolha sua assinatura'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<SubscriptionPlan>>(
                    future: plansFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const SizedBox(
                          height: 120,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final plans = snapshot.data ?? const [];
                      if (plans.isEmpty) {
                        return Text(
                          context.tr('Nenhum plano disponível no momento.'),
                          style: TextStyle(color: palette.muted),
                        );
                      }
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 720;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final plan in plans)
                                SizedBox(
                                  width: wide
                                      ? (constraints.maxWidth - 12) / 2
                                      : constraints.maxWidth,
                                  child: _PlanChoice(
                                    plan: plan,
                                    selected:
                                        selectedPlanInterval == plan.interval,
                                    onTap: () => setState(() =>
                                        selectedPlanInterval = plan.interval),
                                  ),
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  AppButton(
                      onPressed: loading ? null : _checkout,
                      loading: loading,
                      label: 'Ativar assinatura',
                      icon: Icons.credit_card),
                ] else
                  AppButton(
                      onPressed: loading ? null : _portal,
                      loading: loading,
                      label: 'Gerenciar assinatura',
                      icon: Icons.open_in_new),
                const SizedBox(height: 10),
                TextButton.icon(
                    onPressed: loading ? null : _refresh,
                    icon: const Icon(Icons.refresh),
                    label: Text(context.tr('Atualizar situação'))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LovePanel(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(context.tr('Identidade do site'),
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 14),
                  TextField(
                      controller: name,
                      decoration: InputDecoration(
                          labelText: context.tr('Nome exibido'))),
                  const SizedBox(height: 12),
                  TextField(
                      controller: slug,
                      decoration: InputDecoration(
                          labelText: context.tr('Endereço do site'))),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: locale,
                    decoration:
                        InputDecoration(labelText: context.tr('Idioma padrão')),
                    items: [
                      DropdownMenuItem(
                          value: 'pt-BR', child: Text(context.tr('Português'))),
                      DropdownMenuItem(
                          value: 'en', child: Text(context.tr('English'))),
                      DropdownMenuItem(
                          value: 'es', child: Text(context.tr('Español'))),
                    ],
                    onChanged: (value) =>
                        setState(() => locale = value ?? locale),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                      onPressed: loading ? null : _save,
                      loading: loading,
                      label: 'Salvar alterações',
                      icon: Icons.save_outlined),
                ]),
          ),
          const SizedBox(height: 16),
          LovePanel(
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('Site publicado'),
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(context.tr(tenant?.isPublished == true
                  ? 'Seu site está visível para quem possui o link.'
                  : 'Somente você consegue editar e visualizar no painel.')),
              value: tenant?.isPublished == true,
              onChanged: loading || tenant?.isActive != true
                  ? null
                  : (value) => _run(() => widget.auth.setPublished(value)),
            ),
          ),
          if (tenant?.isPublished == true) ...[
            const SizedBox(height: 12),
            AppButton(
              onPressed: () => launchUrl(AppConfig.publicSiteUri(tenant!.slug),
                  mode: LaunchMode.externalApplication),
              label: 'Abrir meu site',
              icon: Icons.public,
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanChoice extends StatelessWidget {
  const _PlanChoice({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final SubscriptionPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minHeight: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? palette.primary.withValues(alpha: .11)
              : palette.card.withValues(alpha: .82),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? palette.primary : palette.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? palette.primary : palette.muted,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              plan.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: palette.muted, height: 1.35),
            ),
            const SizedBox(height: 12),
            Text(
              '${_money(plan.priceCents, plan.currency)} ${_periodLabel(plan.interval)}',
              style: TextStyle(
                color: palette.primaryDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
