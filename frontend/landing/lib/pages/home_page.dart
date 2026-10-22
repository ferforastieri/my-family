import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../components/seo_head.dart';
import '../components/site_shell.dart';
import '../site_config.dart';

class HomePage extends StatelessComponent {
  const HomePage({super.key});

  @override
  Component build(BuildContext context) => SiteShell(
    showHeader: false,
    child: div([
      const SeoHead(
        title: 'Sião — memórias e rotina em um espaço privado',
        description:
            'Guarde memórias, organize a rotina e aproxime quem você ama em um espaço digital privado para casais e filhos.',
        path: '/',
        jsonLd: {
          '@context': 'https://schema.org',
          '@graph': [
            {'@type': 'Organization', 'name': 'Sião', 'url': siteUrl},
            {
              '@type': 'SoftwareApplication',
              'name': 'Sião',
              'url': siteUrl,
              'applicationCategory': 'LifestyleApplication',
              'operatingSystem': 'Web, Android',
              'description':
                  'Espaço digital privado para memórias e rotina familiar.',
            },
          ],
        },
      ),
      section(classes: 'hero', [
        div([
          img(
            src: '/api/public/branding/logo',
            width: 220,
            alt: 'Sião',
            classes: 'hero-logo',
          ),
          h1([.text('Sua família não cabe em um grupo de mensagens.')]),
          p(classes: 'lede', [
            .text(
              'Memórias, cartas, listas, localização e pequenos rituais reunidos em uma casa digital privada — com a identidade de vocês.',
            ),
          ]),
          div(classes: 'actions', [
            a(href: appHome, classes: 'ds-button ds-button-primary', [
              .text('Criar minha família'),
            ]),
            a(href: appHome, classes: 'ds-button ds-button-ghost', [
              .text('Entrar'),
            ]),
          ]),
        ]),
      ]),
      section(classes: 'section', [
        p(classes: 'eyebrow', [.text('Apresentação')]),
        h2([.text('Um lugar para a vida de vocês.')]),
        p(classes: 'lede', [
          .text(
            'O Sião reúne o que a família guarda, organiza e vive junto. Sem feed, sem excesso de notificações e sem transformar a intimidade de vocês em conteúdo público.',
          ),
        ]),
        div(classes: 'feature-list', [
          _feature(
            'Memórias e história',
            'Fotos, cartas, notas e a jornada da família em um só lugar.',
          ),
          _feature(
            'Rotina compartilhada',
            'Listas, lembretes e pequenos rituais que aproximam.',
          ),
          _feature(
            'Conversa e presença',
            'Chat, jogos e localização para estar perto de verdade.',
          ),
          _feature(
            'Privacidade por família',
            'Cada família tem seu espaço isolado, acessível por convite.',
          ),
        ]),
      ]),
      section(classes: 'section', [
        p(classes: 'eyebrow', [.text('Plano')]),
        h2([.text('Comece no Free. Libere o restante quando quiser.')]),
        div(classes: 'feature-list', [
          _plan(
            'Free',
            'R\$ 0',
            'para sempre',
            const [
              'Todas as funções essenciais',
              'Até 10 fotos',
              'Localização em tempo real',
            ],
            'Começar grátis',
          ),
          _plan(
            'Mensal',
            'R\$ 30,00',
            'por mês',
            const [
              'Todas as funções liberadas',
              'Fotos sem limite',
              'Cancele quando quiser',
            ],
            'Criar conta e assinar',
          ),
          _plan(
            'Anual',
            'R\$ 300,00',
            'por ano',
            const [
              'Todas as funções liberadas',
              'Fotos sem limite',
              'Melhor custo-benefício',
            ],
            'Criar conta e assinar',
          ),
        ]),
      ]),
    ]),
  );

  Component _feature(String title, String body) => article(classes: 'feature', [
    h3([.text(title)]),
    p([.text(body)]),
  ]);

  Component _plan(
    String title,
    String price,
    String cadence,
    List<String> features,
    String action,
  ) =>
      article(classes: 'feature', [
        h3([.text(title)]),
        p([strong([.text(price)]), .text(' $cadence')]),
        for (final feature in features) p([.text('✓ $feature')]),
        a(href: appHome, classes: 'ds-button ds-button-primary', [.text(action)]),
      ]);
}
