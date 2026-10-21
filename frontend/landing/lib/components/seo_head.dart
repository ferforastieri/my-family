import 'dart:convert';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../site_config.dart';

class SeoHead extends StatelessComponent {
  const SeoHead({
    required this.title,
    required this.description,
    required this.path,
    this.noIndex = false,
    this.jsonLd,
    super.key,
  });

  final String title;
  final String description;
  final String path;
  final bool noIndex;
  final Object? jsonLd;

  @override
  Component build(BuildContext context) {
    final canonical = '$siteUrl${path == '/' ? '' : path}';
    return Document.head(
      title: title,
      meta: {
        'description': description,
        'robots': noIndex ? 'noindex,nofollow' : 'index,follow',
        'og:type': 'website',
        'og:site_name': 'Sião',
        'og:title': title,
        'og:description': description,
        'og:url': canonical,
        'twitter:card': 'summary_large_image',
        'twitter:title': title,
        'twitter:description': description,
      },
      children: [
        link(rel: 'canonical', href: canonical),
        if (jsonLd != null)
          script(
            attributes: const {'type': 'application/ld+json'},
            content: jsonEncode(jsonLd),
          ),
      ],
    );
  }
}
