import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../site_config.dart';

class SiteShell extends StatelessComponent {
  const SiteShell({
    required this.child,
    this.showHeader = true,
    super.key,
  });

  final Component child;
  final bool showHeader;

  @override
  Component build(BuildContext context) => div([
    a(href: '#conteudo', classes: 'skip', [.text('Pular para o conteúdo')]),
    if (showHeader)
      header(classes: 'site-header', [
        nav(
          classes: 'nav',
          attributes: const {'aria-label': 'Navegação principal'},
          [
            a(href: '/', classes: 'brand', [
              img(src: '/assets/family-logo.png', width: 46, height: 46, alt: ''),
              span([.text('Sião')]),
            ]),
            div(classes: 'nav-links', [
              a(href: '/#faq', [.text('Dúvidas')]),
              a(href: appHome, classes: 'ds-button ds-button-ghost', [
                .text('Entrar'),
              ]),
            ]),
          ],
        ),
      ]),
    main_(id: 'conteudo', [child]),
    footer(classes: 'site-footer', [
      div(classes: 'footer-grid', [
        div([
          h2([.text('Sião')]),
          p([.text('Um espaço privado para o que aproxima vocês.')]),
        ]),
        _footerColumn('Sião', [
        ]),
        _footerColumn('Confiança', [
          ('Política de privacidade', '/#/privacidade'),
          ('Termos de uso', '/#/termos'),
        ]),
        _footerColumn('Acesso', [
          ('Criar minha família', appHome),
          ('Abrir aplicativo', appHome),
        ]),
      ]),
      p(classes: 'copyright', [.text('© 2026 Sião.')]),
    ]),
  ]);

  Component _footerColumn(String title, List<(String, String)> links) => div([
    h3([.text(title)]),
    nav(
      attributes: {'aria-label': title},
      [
        for (final item in links) a(href: item.$2, [.text(item.$1)]),
      ],
    ),
  ]);
}
