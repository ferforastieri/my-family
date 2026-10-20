import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../site_config.dart';

class SiteShell extends StatelessComponent {
  const SiteShell({required this.child, super.key});

  final Component child;

  @override
  Component build(BuildContext context) => div([
    a(href: '#conteudo', classes: 'skip', [.text('Pular para o conteúdo')]),
    header(classes: 'site-header', [
      nav(
        classes: 'nav',
        attributes: const {'aria-label': 'Navegação principal'},
        [
          a(href: '/', classes: 'brand', [
            img(src: '/assets/family-logo.png', width: 46, height: 46, alt: ''),
            span([.text('Nossa Família')]),
          ]),
          div(classes: 'nav-links', [
            a(href: '/recursos', [.text('Recursos')]),
            a(href: '/como-funciona', [.text('Como funciona')]),
            a(href: '/seguranca', [.text('Privacidade')]),
            a(href: '/faq', [.text('Dúvidas')]),
            a(href: downloadUrl, [.text('Baixar app')]),
            a(href: '/cadastro', classes: 'button', [.text('Entrar')]),
          ]),
        ],
      ),
    ]),
    main_(id: 'conteudo', [child]),
    footer(classes: 'site-footer', [
      div(classes: 'footer-grid', [
        div([
          h2([.text('Nossa Família')]),
          p([.text('Um espaço privado para o que aproxima vocês.')]),
        ]),
        _footerColumn('Produto', [
          ('Recursos', '/recursos'),
          ('Como funciona', '/como-funciona'),
          ('Perguntas frequentes', '/faq'),
        ]),
        _footerColumn('Confiança', [
          ('Segurança e privacidade', '/seguranca'),
          ('Política de privacidade', '/privacidade'),
          ('Termos de uso', '/termos'),
        ]),
        _footerColumn('Acesso', [
          ('Criar minha família', '/cadastro'),
          ('Abrir aplicativo', appUrl),
          ('Abrir painel', panelUrl),
          ('Baixar app', downloadUrl),
        ]),
      ]),
      p(classes: 'copyright', [.text('© 2026 Nossa Família.')]),
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
