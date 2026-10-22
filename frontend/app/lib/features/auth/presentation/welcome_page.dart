import 'package:flutter/material.dart';
import '../../../core/widgets/app_brand.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_controller.dart';
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

    return Scaffold(
      body: LoveBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  isWide ? 38 : 20,
                  18,
                  isWide ? 38 : 20,
                  40,
                ),
                children: [
                  const SizedBox(height: 26),
                  _WelcomeHero(
                    wide: isWide,
                    onCreate: () => _openAuth(
                      context,
                      register: true,
                      tenantSlug: tenantSlug,
                      invitationToken: invitationToken,
                    ),
                    onLogin: () => _openAuth(
                      context,
                      register: false,
                      tenantSlug: tenantSlug,
                    ),
                  ),
                  const SizedBox(height: 46),
                  _WelcomeFeatures(wide: isWide),
                  const SizedBox(height: 46),
                  _WelcomePrivacy(wide: isWide),
                  const SizedBox(height: 46),
                  _WelcomeFaq(wide: isWide),
                  const SizedBox(height: 46),
                  _WelcomeFinalCta(
                    wide: isWide,
                    onCreate: () => _openAuth(
                      context,
                      register: true,
                      tenantSlug: tenantSlug,
                      invitationToken: invitationToken,
                    ),
                  ),
                  const SizedBox(height: 26),
                  _WelcomeFooter(
                    palette: palette,
                    onTerms: () => _openLegal(context, 'termos'),
                    onPrivacy: () => _openLegal(context, 'privacidade'),
                    onLogin: () => _openAuth(
                      context,
                      register: false,
                      tenantSlug: tenantSlug,
                    ),
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
    final copy = Column(
      crossAxisAlignment:
          wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        AppBrandLogo(
          width: wide ? 250 : 200,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 18),
        Text(
          'Sua família não cabe em um grupo de mensagens.',
          textAlign: wide ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            color: palette.foreground,
            fontSize: wide ? 38 : 30,
            height: 1.08,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Memórias, cartas, listas, localização e pequenos rituais reunidos '
          'em uma casa digital privada — com a identidade de vocês.',
          textAlign: wide ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            color: palette.muted,
            fontSize: 17,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: wide ? WrapAlignment.start : WrapAlignment.center,
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

    final memoryLine = _WelcomeMemoryLine(palette: palette);

    if (!wide) {
      return Column(
        children: [
          copy,
          const SizedBox(height: 28),
          memoryLine,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 11, child: copy),
        const SizedBox(width: 42),
        Expanded(flex: 9, child: memoryLine),
      ],
    );
  }
}

class _WelcomeMemoryLine extends StatelessWidget {
  const _WelcomeMemoryLine({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MemoryPreview(
          palette: palette,
          icon: FamilyIcons.photoLibraryOutlined,
          label: 'Memórias',
          title: 'Nosso primeiro lar',
          text:
              'A foto, a música daquele dia e o texto que ninguém quer esquecer.',
        ),
        const SizedBox(height: 12),
        _MemoryPreview(
          palette: palette,
          icon: FamilyIcons.checklistOutlined,
          label: 'Rotina',
          title: 'Lista da semana',
          text: 'Mercado, escola e aquele bolo que ficou prometido.',
        ),
        const SizedBox(height: 12),
        _MemoryPreview(
          palette: palette,
          icon: FamilyIcons.locationOnOutlined,
          label: 'Perto',
          title: 'Cheguei bem',
          text:
              'Localização compartilhada apenas com quem faz parte da família.',
        ),
      ],
    );
  }
}

class _MemoryPreview extends StatelessWidget {
  const _MemoryPreview({
    required this.palette,
    required this.icon,
    required this.label,
    required this.title,
    required this.text,
  });

  final AppPalette palette;
  final IconData icon;
  final String label;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return FamilyCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: palette.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: palette.primary,
                    fontSize: 10,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: TextStyle(
                    color: palette.foreground,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: TextStyle(color: palette.muted, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeFeatures extends StatelessWidget {
  const _WelcomeFeatures({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final features = [
      (
        FamilyIcons.photoLibraryOutlined,
        'Memórias',
        'Fotos, vídeos, álbuns, cartas e a história da família organizados sem se perder no feed.',
      ),
      (
        FamilyIcons.checklistOutlined,
        'Rotina compartilhada',
        'Listas, notas e lembretes que todos podem acompanhar em tempo real.',
      ),
      (
        FamilyIcons.chatBubbleOutline,
        'Conversa de verdade',
        'Chat, jogos e pequenos espaços de conexão sem distrações de uma rede social.',
      ),
      (
        FamilyIcons.shieldOutlined,
        'Segurança',
        'Cada família tem um ambiente isolado, acessível somente por convite.',
      ),
      (
        FamilyIcons.paletteOutlined,
        'Identidade própria',
        'Escolha a cor principal e a tipografia que combinam com a história de vocês.',
      ),
      (
        FamilyIcons.peopleOutline,
        'Web e Android',
        'Use em casa ou no caminho, com a mesma experiência e os mesmos dados.',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UM LUGAR, MUITOS VÍNCULOS',
          style: TextStyle(
            color: palette.primary,
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'O cotidiano também merece ser guardado.',
          style: TextStyle(
            color: palette.foreground,
            fontSize: wide ? 30 : 25,
            height: 1.12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 840
                ? 3
                : constraints.maxWidth >= 560
                    ? 2
                    : 1;
            final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final item in features)
                  SizedBox(
                    width: width,
                    child: FamilyCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: palette.primary.withValues(alpha: .11),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(item.$1, color: palette.primary),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            item.$2,
                            style: TextStyle(
                              color: palette.foreground,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.$3,
                            style: TextStyle(
                              color: palette.muted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
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

class _WelcomePrivacy extends StatelessWidget {
  const _WelcomePrivacy({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return FamilyCard(
      padding: EdgeInsets.all(wide ? 28 : 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(FamilyIcons.lockOutline, color: palette.primary, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Memórias da família não são conteúdo público.',
                  style: TextStyle(
                    color: palette.foreground,
                    fontSize: wide ? 23 : 20,
                    height: 1.16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'O Sião é um espaço privado, feito para quem você escolheu. '
                  'A família tem o próprio ambiente, com acesso por convite e '
                  'dados separados de outras famílias.',
                  style: TextStyle(color: palette.muted, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeFaq extends StatelessWidget {
  const _WelcomeFaq({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    const items = [
      (
        'Como começo?',
        'Crie sua conta com nome, email e senha. Em poucos passos o espaço da sua família está pronto.',
      ),
      (
        'Outras famílias veem meus dados?',
        'Não. Cada família tem um ambiente isolado; membros de outras famílias não acessam suas memórias, arquivos ou localização.',
      ),
      (
        'Posso participar de mais de uma família?',
        'Sim. A mesma conta pode participar de mais de uma família e alternar entre elas sem criar outra conta.',
      ),
      (
        'Quem decide compartilhar a localização?',
        'Cada pessoa decide individualmente se compartilha a própria localização. O ajuste fica em Perfil → Preferências → Localização.',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PERGUNTAS FREQUENTES',
          style: TextStyle(
            color: palette.primary,
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Antes de abrir a porta, tire suas dúvidas.',
          style: TextStyle(
            color: palette.foreground,
            fontSize: wide ? 28 : 24,
            height: 1.12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        for (var index = 0; index < items.length; index++) ...[
          SizedBox(
            width: double.infinity,
            child: FamilyCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    items[index].$1,
                    style: TextStyle(
                      color: palette.foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    items[index].$2,
                    style: TextStyle(color: palette.muted, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          if (index < items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _WelcomeFinalCta extends StatelessWidget {
  const _WelcomeFinalCta({
    required this.wide,
    required this.onCreate,
  });

  final bool wide;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: EdgeInsets.all(wide ? 32 : 24),
        child: Column(
          children: [
            Text(
              'Abra a porta da casa digital da sua família.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: wide ? 28 : 23,
                height: 1.15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Crie sua conta e comece a guardar o que importa.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: .82),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            FamilyFilledButton.icon(
              onPressed: onCreate,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.onPrimary,
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              icon: const Icon(FamilyIcons.personAddAlt1Outlined),
              label: const Text('Criar minha família'),
            ),
          ],
        ),
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
