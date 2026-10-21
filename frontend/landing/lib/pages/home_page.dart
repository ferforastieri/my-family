import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../components/demo_button.dart';
import '../components/seo_head.dart';
import '../components/site_shell.dart';
import '../site_config.dart';

class HomePage extends StatelessComponent {
  const HomePage({super.key});

  @override
  Component build(BuildContext context) => SiteShell(
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
      if (turnstileSiteKey.isNotEmpty)
        Document.head(
          children: const [
            script(
              src: 'https://challenges.cloudflare.com/turnstile/v0/api.js',
              async: true,
              defer: true,
            ),
          ],
        ),
      section(classes: 'hero', [
        div([
          p(classes: 'eyebrow', [
            .text('Feito para a vida que vocês constroem'),
          ]),
          h1([
            .text('Sua família não cabe em um '),
            em([.text('grupo de mensagens.')]),
          ]),
          p(classes: 'lede', [
            .text(
              'Memórias, cartas, listas, localização e pequenos rituais reunidos em uma casa digital privada — com a identidade de vocês.',
            ),
          ]),
          div(classes: 'actions', [
            a(href: '/cadastro', classes: 'button primary', [
              .text('Criar minha família'),
            ]),
            const DemoButton(label: 'Experimentar a demo'),
          ]),
        ]),
        div(
          classes: 'memory-line',
          attributes: const {
            'aria-label': 'Uma linha conecta três memórias familiares',
          },
          [
            _memory(
              '12 de maio',
              'Nosso primeiro lar',
              'A foto, a música daquele dia e o texto que ninguém quer esquecer.',
            ),
            _memory(
              'Hoje',
              'Lista da semana',
              'Mercado, escola e aquele bolo que ficou prometido.',
            ),
            _memory(
              'Sempre perto',
              'Cheguei bem',
              'Localização compartilhada apenas com quem faz parte da família.',
            ),
          ],
        ),
      ]),
      section(classes: 'section', [
        p(classes: 'eyebrow', [.text('Um lugar, muitos vínculos')]),
        h2([.text('O cotidiano também merece ser guardado.')]),
        div(classes: 'feature-list', [
          _feature(
            'Memórias',
            'Fotos, vídeos, álbuns, cartas e a história da família organizados sem se perder no feed.',
          ),
          _feature(
            'Rotina compartilhada',
            'Listas, notas e lembretes que todos podem acompanhar em tempo real.',
          ),
          _feature(
            'Conversa de verdade',
            'Chat, jogos e pequenos espaços de conexão sem distrações de uma rede social.',
          ),
          _feature(
            'Segurança',
            'Cada família tem um ambiente isolado, acessível somente por convite.',
          ),
          _feature(
            'Identidade própria',
            'Escolha a cor principal e a tipografia que combinam com a história de vocês.',
          ),
          _feature(
            'Web e Android',
            'Use em casa ou no caminho, com a mesma experiência e os mesmos dados.',
          ),
        ]),
      ]),
      section(classes: 'section privacy', [
        p(classes: 'eyebrow', [.text('Privado desde o começo')]),
        h2([.text('Memórias da família não são conteúdo público.')]),
        p(classes: 'lede', [
          .text(
            'O acesso acontece por convite. Cada família vê somente seu espaço, enquanto a plataforma acompanha a operação — nunca uma galeria com o conteúdo privado.',
          ),
        ]),
        a(href: '/seguranca', classes: 'button', [
          .text('Conhecer a proteção dos dados'),
        ]),
      ]),
      section(classes: 'section cta', [
        div([
          p(classes: 'eyebrow', [.text('Comece do seu jeito')]),
          h2([.text('Abra a porta da casa digital da sua família.')]),
        ]),
        div(classes: 'actions', [
          a(href: '/cadastro', classes: 'button primary', [
            .text('Criar minha família'),
          ]),
          const DemoButton(label: 'Ver por dentro'),
        ]),
      ]),
    ]),
  );

  Component _memory(String date, String title, String body) =>
      article(classes: 'memory', [
        small([.text(date)]),
        strong([.text(title)]),
        p([.text(body)]),
      ]);

  Component _feature(String title, String body) => article(classes: 'feature', [
    h3([.text(title)]),
    p([.text(body)]),
  ]);
}
