import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/love_background.dart';
import '../domain/marketing_copy.dart';

class MarketingPage extends StatefulWidget {
  const MarketingPage({super.key, required this.initialLocale});

  final MarketingLocale initialLocale;

  @override
  State<MarketingPage> createState() => _MarketingPageState();
}

class _MarketingPageState extends State<MarketingPage> {
  late MarketingLocale locale = widget.initialLocale;

  @override
  Widget build(BuildContext context) {
    final t = marketingCopy[locale]!;
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LoveBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: palette.bgStart.withValues(alpha: .94),
              surfaceTintColor: Colors.transparent,
              title: Row(
                children: [
                  const Text('🌸', style: TextStyle(fontSize: 25)),
                  const SizedBox(width: 9),
                  Flexible(
                    child: Text(
                      t.brand,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              actions: [
                DropdownButtonHideUnderline(
                  child: DropdownButton<MarketingLocale>(
                    value: locale,
                    borderRadius: BorderRadius.circular(16),
                    items: MarketingLocale.values
                        .map((item) => DropdownMenuItem(
                              value: item,
                              child: Text(item.code.toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => locale = value);
                    },
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/login?locale=${locale.code}'),
                  child: Text(t.login),
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 70, 20, 90),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 820;
                        final intro = _HeroCopy(
                          locale: locale,
                          copy: t,
                        );
                        final preview = _PreviewCard(copy: t);
                        return wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(flex: 11, child: intro),
                                  const SizedBox(width: 58),
                                  Expanded(flex: 9, child: preview),
                                ],
                              )
                            : Column(
                                children: [
                                  intro,
                                  const SizedBox(height: 44),
                                  preview,
                                ],
                              );
                      },
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: ColoredBox(
                color: palette.card.withValues(alpha: .46),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 86,
                      ),
                      child: Column(
                        children: [
                          Text(
                            t.featuresTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 36,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 36),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final columns =
                                  constraints.maxWidth >= 760 ? 2 : 1;
                              final width =
                                  (constraints.maxWidth - (columns - 1) * 14) /
                                      columns;
                              return Wrap(
                                spacing: 14,
                                runSpacing: 14,
                                children: t.features
                                    .map((feature) => SizedBox(
                                          width: width,
                                          child: _FeatureCard(feature: feature),
                                        ))
                                    .toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 90, horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      t.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 34,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: () =>
                          context.go('/signup?locale=${locale.code}'),
                      icon: const Icon(Icons.favorite_outline),
                      label: Text(t.primary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.locale, required this.copy});

  final MarketingLocale locale;
  final MarketingCopy copy;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: palette.card.withValues(alpha: .72),
            border: Border.all(color: palette.border),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              '♥  ${copy.eyebrow.toUpperCase()}',
              style: TextStyle(
                color: palette.primaryDark,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          copy.title,
          style: const TextStyle(
            fontSize: 48,
            height: 1.02,
            letterSpacing: -1.4,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          copy.description,
          style: TextStyle(
            color: palette.muted,
            fontSize: 17,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => context.go('/signup?locale=${locale.code}'),
              icon: const Icon(Icons.favorite_outline),
              label: Text(copy.primary),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/demo?locale=${locale.code}'),
              icon: const Icon(Icons.visibility_outlined),
              label: Text(copy.demo),
            ),
          ],
        ),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.copy});

  final MarketingCopy copy;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.card.withValues(alpha: .92),
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: .15),
            blurRadius: 42,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [palette.primary, palette.primaryDark],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(copy.brand,
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text(
                    copy.eyebrow,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.35,
              children: copy.features
                  .map((feature) => DecoratedBox(
                        decoration: BoxDecoration(
                          color: palette.bgStart,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: palette.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(feature.$1,
                                  style: const TextStyle(fontSize: 23)),
                              Text(
                                feature.$2,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});

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
        padding: const EdgeInsets.all(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(feature.$1, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.$2,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(feature.$3,
                      style: TextStyle(color: palette.muted, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
