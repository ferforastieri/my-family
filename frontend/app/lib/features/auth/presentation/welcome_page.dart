import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_brand.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/love_background.dart';
import 'package:family_ui/family_ui.dart';
import 'auth_sheet.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({
    super.key,
    required this.auth,
    required this.toast,
  });

  final AuthController auth;
  final ToastController toast;

  void _openAuth(
    BuildContext context, {
    required bool register,
    String? tenantSlug,
    String? invitationToken,
  }) {
    showAppSheet<void>(
      context: context,
      builder: (sheetContext) => AuthSheet(
        auth: auth,
        toast: toast,
        initialRegisterMode: register,
        tenantSlug: tenantSlug,
        invitationToken: invitationToken,
        onAuthenticated: () => Navigator.of(sheetContext).pop(),
      ),
    );
  }

  void _openLegal(BuildContext context, String path) {
    context.push('/$path');
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final routerState = GoRouterState.of(context);
    final tenantSlug = routerState.uri.queryParameters['tenantSlug'];
    final invitationToken = routerState.uri.queryParameters['invitation'];
    final isWide = MediaQuery.sizeOf(context).width >= 760;

    void create() => _openAuth(
          context,
          register: true,
          tenantSlug: tenantSlug,
          invitationToken: invitationToken,
        );
    void login() => _openAuth(
          context,
          register: false,
          tenantSlug: tenantSlug,
        );

    return Scaffold(
      body: LoveBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  isWide ? 38 : 20,
                  24,
                  isWide ? 38 : 20,
                  40,
                ),
                children: [
                  _WelcomeHero(
                    wide: isWide,
                    onCreate: create,
                    onLogin: login,
                  ),
                  SizedBox(height: isWide ? 52 : 42),
                  _WelcomePresentation(wide: isWide),
                  SizedBox(height: isWide ? 52 : 42),
                  _WelcomePlans(
                    wide: isWide,
                    onCreate: create,
                  ),
                  const SizedBox(height: 30),
                  _WelcomeFooter(
                    palette: palette,
                    onTerms: () => _openLegal(context, 'termos'),
                    onPrivacy: () => _openLegal(context, 'privacidade'),
                    onLogin: login,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({
    required this.wide,
    required this.onCreate,
    required this.onLogin,
  });

  final bool wide;
  final VoidCallback onCreate;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppBrandLogo(width: wide ? 250 : 200, fit: BoxFit.contain),
        const SizedBox(height: 18),
        Text(
          'Sua família não cabe em um grupo de mensagens.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.foreground,
            fontSize: wide ? 42 : 31,
            height: 1.06,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Text(
            'Memórias, cartas, listas, localização e pequenos rituais reunidos '
            'em uma casa digital privada — com a identidade de vocês.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.muted,
              fontSize: wide ? 18 : 16,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 26),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            FamilyFilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(FamilyIcons.personAddAlt1Outlined),
              label: const Text('Criar minha família'),
            ),
            FamilyOutlinedButton.icon(
              onPressed: onLogin,
              icon: const Icon(FamilyIcons.login),
              label: const Text('Entrar'),
            ),
          ],
        ),
      ],
    );
  }
}

class _WelcomePresentation extends StatelessWidget {
  const _WelcomePresentation({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    const points = [
      (
        FamilyIcons.photoLibraryOutlined,
        'Memórias e história',
        'Fotos, cartas, notas e a jornada da família em um só lugar.',
      ),
      (
        FamilyIcons.checklistOutlined,
        'Rotina compartilhada',
        'Listas, lembretes e pequenos rituais que aproximam.',
      ),
      (
        FamilyIcons.chatBubbleOutline,
        'Conversa e presença',
        'Chat, jogos e localização para estar perto de verdade.',
      ),
      (
        FamilyIcons.shieldOutlined,
        'Privacidade por família',
        'Cada família tem seu espaço isolado, acessível por convite.',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'APRESENTAÇÃO',
          style: TextStyle(
            color: palette.primary,
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Um lugar para a vida de vocês.',
          style: TextStyle(
            color: palette.foreground,
            fontSize: wide ? 31 : 26,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Text(
            'O Sião reúne o que a família guarda, organiza e vive junto. '
            'Sem feed, sem excesso de notificações e sem transformar a '
            'intimidade de vocês em conteúdo público.',
            style: TextStyle(color: palette.muted, fontSize: 16, height: 1.5),
          ),
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 760 ? 2 : 1;
            final width = (constraints.maxWidth - (columns - 1) * 20) / columns;
            return Wrap(
              spacing: 20,
              runSpacing: 18,
              children: [
                for (final point in points)
                  SizedBox(
                    width: width,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(point.$1, color: palette.primary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                point.$2,
                                style: TextStyle(
                                  color: palette.foreground,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                point.$3,
                                style: TextStyle(
                                  color: palette.muted,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _WelcomePlans extends StatelessWidget {
  const _WelcomePlans({required this.wide, required this.onCreate});

  final bool wide;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final plans = [
      _LandingPlan(
        title: 'Free',
        price: 'R\$ 0',
        cadence: 'para sempre',
        description: 'Comece sem pagar nada.',
        features: const [
          'Todas as funções essenciais',
          'Até 10 fotos',
          'Localização em tempo real',
        ],
        action: 'Começar grátis',
        highlighted: false,
      ),
      _LandingPlan(
        title: 'Mensal',
        price: 'R\$ 30,00',
        cadence: 'por mês',
        description: 'Para viver o Sião sem limites.',
        features: const [
          'Todas as funções liberadas',
          'Fotos sem limite',
          'Cancele quando quiser',
        ],
        action: 'Criar conta e assinar',
        highlighted: true,
      ),
      _LandingPlan(
        title: 'Anual',
        price: 'R\$ 300,00',
        cadence: 'por ano',
        description: 'A melhor escolha para a família.',
        features: const [
          'Todas as funções liberadas',
          'Fotos sem limite',
          'Melhor custo-benefício',
        ],
        action: 'Criar conta e assinar',
        highlighted: false,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PLANO',
          style: TextStyle(
            color: palette.primary,
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Comece no Free. Libere o restante quando quiser.',
          style: TextStyle(
            color: palette.foreground,
            fontSize: wide ? 29 : 24,
            height: 1.12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 18),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < plans.length; i++) ...[
                Expanded(child: _PlanCard(plan: plans[i], onPressed: onCreate)),
                if (i < plans.length - 1) const SizedBox(width: 14),
              ],
            ],
          )
        else
          Column(
            children: [
              for (var i = 0; i < plans.length; i++) ...[
                _PlanCard(plan: plans[i], onPressed: onCreate),
                if (i < plans.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
      ],
    );
  }
}

class _LandingPlan {
  const _LandingPlan({
    required this.title,
    required this.price,
    required this.cadence,
    required this.description,
    required this.features,
    required this.action,
    required this.highlighted,
  });

  final String title;
  final String price;
  final String cadence;
  final String description;
  final List<String> features;
  final String action;
  final bool highlighted;
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.onPressed});

  final _LandingPlan plan;
  final VoidCallback onPressed;

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
                  plan.title,
                  style: TextStyle(
                    color: palette.foreground,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (plan.highlighted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Popular',
                    style: TextStyle(
                      color: palette.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            plan.price,
            style: TextStyle(
              color: palette.primary,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(plan.cadence, style: TextStyle(color: palette.muted)),
          const SizedBox(height: 8),
          Text(plan.description, style: TextStyle(color: palette.muted)),
          const SizedBox(height: 16),
          for (final feature in plan.features)
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FamilyFilledButton(
              onPressed: onPressed,
              child: Text(plan.action),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeFooter extends StatelessWidget {
  const _WelcomeFooter({
    required this.palette,
    required this.onTerms,
    required this.onPrivacy,
    required this.onLogin,
  });

  final AppPalette palette;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(
          '© 2026 Sião',
          style: TextStyle(color: palette.muted, fontSize: 12),
        ),
        const SizedBox(width: 8),
        _FooterLink(label: 'Termos', onTap: onTerms),
        _FooterLink(label: 'Privacidade', onTap: onPrivacy),
        _FooterLink(label: 'Entrar', onTap: onLogin),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      ),
      child: Text(label),
    );
  }
}
