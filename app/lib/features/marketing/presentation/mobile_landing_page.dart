import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/love_background.dart';
import '../domain/marketing_copy.dart';

class MobileLandingPage extends StatelessWidget {
  const MobileLandingPage({
    super.key,
    required this.auth,
    required this.locale,
  });

  final AuthController auth;
  final MarketingLocale locale;

  @override
  Widget build(BuildContext context) {
    final t = marketingCopy[locale]!;
    final palette = Theme.of(context).extension<AppPalette>()!;
    final signedIn = auth.user != null;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LoveBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: palette.bgStart.withValues(alpha: .94),
              surfaceTintColor: Colors.transparent,
              title: Text(
                t.brand,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      context.go('/login/cliente?locale=${locale.code}'),
                  child: Text(t.login),
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 42, 18, 36),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HeroPanel(
                          t: t,
                          palette: palette,
                          signedIn: signedIn,
                          onPrimary: () => context.go(
                            signedIn ? _signedInPath(auth) : '/signup',
                          ),
                          onDemo: () =>
                              context.go('/demo?locale=${locale.code}'),
                          onLogin: () => context
                              .go('/login/cliente?locale=${locale.code}'),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          t.featuresTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: palette.primaryDark,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final feature in t.features)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _FeatureTile(feature: feature),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _signedInPath(AuthController auth) {
    final tenant = auth.tenant;
    if (tenant == null) return '/familias';
    return tenant.isActive ? '/home' : '/billing';
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.t,
    required this.palette,
    required this.signedIn,
    required this.onPrimary,
    required this.onDemo,
    required this.onLogin,
  });

  final MarketingCopy t;
  final AppPalette palette;
  final bool signedIn;
  final VoidCallback onPrimary;
  final VoidCallback onDemo;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.card.withValues(alpha: .94),
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: .14),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.eyebrow,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.primaryDark,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                height: 1.05,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              t.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.muted,
                fontSize: 16,
                height: 1.42,
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              onPressed: onPrimary,
              icon: signedIn
                  ? Icons.arrow_forward_rounded
                  : Icons.family_restroom_outlined,
              label: signedIn ? 'Continuar' : t.primary,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onDemo,
              icon: const Icon(Icons.visibility_outlined),
              label: Text(t.demo),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: onLogin,
              child: Text(t.login),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.feature});

  final (String, String, String) feature;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.card,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                feature.$1,
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.$2,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    feature.$3,
                    style: TextStyle(color: palette.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
