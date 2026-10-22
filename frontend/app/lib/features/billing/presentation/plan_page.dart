import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_fixed_header_scroll_view.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/love_background.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../data/family_repository.dart';
import 'package:family_ui/family_ui.dart';

class PlanPage extends StatefulWidget {
  const PlanPage({
    super.key,
    required this.auth,
    required this.repository,
    required this.toast,
  });

  final AuthController auth;
  final FamilyRepository repository;
  final ToastController toast;

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  late Future<List<Map<String, dynamic>>> prices;
  bool opening = false;

  @override
  void initState() {
    super.initState();
    prices = widget.repository.getPlanPrices();
  }

  Future<void> _checkout(String plan) async {
    setState(() => opening = true);
    try {
      final url = await widget.repository.startCheckout(plan);
      if (url == null) throw StateError('Não foi possível abrir o checkout.');
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      await widget.auth.refreshMe();
    } catch (error) {
      widget.toast.error(error.toString());
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  Future<void> _portal() async {
    setState(() => opening = true);
    try {
      final url = await widget.repository.openBillingPortal();
      if (url == null) throw StateError('Nenhuma assinatura encontrada.');
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      await widget.auth.refreshMe();
    } catch (error) {
      widget.toast.error(error.toString());
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  String _price(Map<String, dynamic> row) {
    final amount = (row['amountMinor'] as num?)?.toInt() ?? 0;
    return 'R\$ ${(amount / 100).toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return ListenableBuilder(
      listenable: widget.auth,
      builder: (context, _) {
        final user = widget.auth.user;
        final currentPlan = user?.planCode ?? 'free';
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: LoveBackground(
            child: AppFixedHeaderScrollView(
              header: const AppPageHeader(
                title: 'Plano',
                subtitle: 'Escolha como continuar sua história.',
                icon: FamilyIcons.starRounded,
              ),
              children: [
                _CurrentPlanCard(
                  plan: currentPlan,
                  palette: palette,
                  onManage: currentPlan == 'monthly' || currentPlan == 'yearly'
                      ? _portal
                      : null,
                ),
                const SizedBox(height: 18),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: prices,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SkeletonBox(height: 220, borderRadius: 20);
                    }
                    final byPlan = {
                      for (final row in snapshot.data!) row['plan']: row,
                    };
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 720;
                        final cards = [
                          _PlanCard(
                            title: 'Free',
                            price: 'R\$ 0',
                            cadence: 'para sempre',
                            current: currentPlan == 'free',
                            features: const [
                              'Todas as funcionalidades',
                              'Até 10 fotos',
                              'Localização em tempo real',
                              'Todas as funções essenciais',
                            ],
                            onSelect: null,
                          ),
                          if (byPlan['monthly'] != null)
                            _PlanCard(
                              title: 'Mensal',
                              price: _price(byPlan['monthly']!),
                              cadence: 'por mês',
                              current: currentPlan == 'monthly',
                              features: const [
                                'Todas as funcionalidades',
                                'Fotos sem limite',
                                'Todas as funções liberadas',
                              ],
                              onSelect: opening ? null : () => _checkout('monthly'),
                            ),
                          if (byPlan['yearly'] != null)
                            _PlanCard(
                              title: 'Anual',
                              price: _price(byPlan['yearly']!),
                              cadence: 'por ano',
                              current: currentPlan == 'yearly',
                              features: const [
                                'Todas as funcionalidades',
                                'Fotos sem limite',
                                'Todas as funções liberadas',
                                'Melhor custo-benefício',
                              ],
                              onSelect: opening ? null : () => _checkout('yearly'),
                            ),
                        ];
                        return wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (var i = 0; i < cards.length; i++) ...[
                                    Expanded(child: cards[i]),
                                    if (i < cards.length - 1)
                                      const SizedBox(width: 14),
                                  ],
                                ],
                              )
                            : Column(
                                children: [
                                  for (var i = 0; i < cards.length; i++) ...[
                                    cards[i],
                                    if (i < cards.length - 1)
                                      const SizedBox(height: 14),
                                  ],
                                ],
                              );
                      },
                    );
                  },
                ),
                const SizedBox(height: 18),
                Text(
                  'O plano Free é o ponto de partida. Você pode mudar de plano quando quiser.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.muted, height: 1.4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({
    required this.plan,
    required this.palette,
    required this.onManage,
  });

  final String plan;
  final AppPalette palette;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    final label = switch (plan) {
      'monthly' => 'Mensal',
      'yearly' => 'Anual',
      _ => 'Free',
    };
    return FamilyCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(FamilyIcons.starRounded, color: palette.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seu plano atual',
                  style: TextStyle(color: palette.muted, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: palette.foreground,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (onManage != null)
            FamilyOutlinedButton(
              onPressed: onManage,
              child: const Text('Gerenciar'),
            ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.cadence,
    required this.features,
    required this.current,
    required this.onSelect,
  });

  final String title;
  final String price;
  final String cadence;
  final List<String> features;
  final bool current;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return FamilyCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: palette.foreground,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (current)
                Chip(
                  label: const Text('Atual'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            price,
            style: TextStyle(
              color: palette.primary,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(cadence, style: TextStyle(color: palette.muted)),
          const SizedBox(height: 16),
          for (final feature in features)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(FamilyIcons.check, color: palette.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(color: palette.foreground, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          if (onSelect != null)
            SizedBox(
              width: double.infinity,
              child: FamilyFilledButton(
                onPressed: onSelect,
                child: const Text('Assinar'),
              ),
            )
          else if (current)
            Center(
              child: Text(
                'Plano ativo',
                style: TextStyle(
                  color: palette.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
