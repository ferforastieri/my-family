import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../components/seo_head.dart';
import '../components/site_shell.dart';

class ContentPage extends StatelessComponent {
  const ContentPage({
    required this.path,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.sections,
    this.faq = false,
    super.key,
  });

  final String path;
  final String eyebrow;
  final String title;
  final String description;
  final List<(String, String)> sections;
  final bool faq;

  @override
  Component build(BuildContext context) => SiteShell(
    child: div([
      SeoHead(
        title: '$title — Nossa Família',
        description: description,
        path: path,
        jsonLd: faq
            ? {
                '@context': 'https://schema.org',
                '@type': 'FAQPage',
                'mainEntity': [
                  for (final item in sections)
                    {
                      '@type': 'Question',
                      'name': item.$1,
                      'acceptedAnswer': {'@type': 'Answer', 'text': item.$2},
                    },
                ],
              }
            : {
                '@context': 'https://schema.org',
                '@type': 'BreadcrumbList',
                'itemListElement': [
                  {
                    '@type': 'ListItem',
                    'position': 1,
                    'name': 'Início',
                    'item': '/',
                  },
                  {'@type': 'ListItem', 'position': 2, 'name': title},
                ],
              },
      ),
      section(classes: 'section content', [
        p(classes: 'eyebrow', [.text(eyebrow)]),
        h1([.text(title)]),
        p(classes: 'lede', [.text(description)]),
        div(classes: 'content-sections', [
          for (final item in sections)
            article([
              h2([.text(item.$1)]),
              p([.text(item.$2)]),
            ]),
        ]),
      ]),
    ]),
  );
}
