import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

class AppDashboardPage extends StatelessWidget {
  const AppDashboardPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.leading,
    this.actions = const [],
    this.maxWidth = 1240,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Scaffold(
      backgroundColor: palette.bgStart,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: palette.bgStart.withValues(alpha: .96),
              surfaceTintColor: Colors.transparent,
              titleSpacing: 18,
              title: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [...actions, const SizedBox(width: 10)],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Divider(height: 1, color: palette.border),
              ),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 24, 18, 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
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
}

class AppMetricGrid extends StatelessWidget {
  const AppMetricGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1050
            ? 4
            : constraints.maxWidth >= 660
                ? 2
                : 1;
        final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }
}

class AppMetricCard extends StatelessWidget {
  const AppMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.caption,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? caption;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final accent = color ?? palette.primary;
    return Container(
      constraints: const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.card,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: .08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: accent),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: const TextStyle(
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              style: TextStyle(color: palette.muted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class AppDashboardSection extends StatelessWidget {
  const AppDashboardSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.card,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(color: palette.muted),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class AppDashboardAction extends StatelessWidget {
  const AppDashboardAction({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
  });

  final String title;
  final String description;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: palette.bgStart,
          border: Border.all(color: palette.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, color: palette.primary),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(color: palette.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 15),
          ],
        ),
      ),
    );
  }
}
