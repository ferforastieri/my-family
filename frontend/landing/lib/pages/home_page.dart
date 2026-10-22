import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

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
            {
              '@type': 'FAQPage',
              'mainEntity': [
                {
                  '@type': 'Question',
                  'name': 'Como começo?',
                  'acceptedAnswer': {
                    '@type': 'Answer',
                    'text':
                        'Crie sua conta com nome, email e senha. Em poucos passos o espaço da sua família está pronto.',
                  },
                },
                {
                  '@type': 'Question',
                  'name': 'Outras famílias veem meus dados?',
                  'acceptedAnswer': {
                    '@type': 'Answer',
                    'text':
                        'Não. Cada família tem um ambiente isolado; membros de outras famílias não acessam suas memórias, arquivos ou localização.',
                  },
                },
                {
                  '@type': 'Question',
                  'name': 'Posso participar de mais de uma família?',
                  'acceptedAnswer': {
                    '@type': 'Answer',
                    'text':
                        'Sim. A mesma conta pode participar de mais de uma família e alternar entre elas sem criar outra conta.',
                  },
                },
                {
                  '@type': 'Question',
                  'name': 'Quem decide compartilhar a localização?',
                  'acceptedAnswer': {
                    '@type': 'Answer',
                    'text':
                        'Cada pessoa decide individualmente se compartilha a própria localização. O ajuste fica em Perfil → Preferências → Localização.',
                  },
                },
              ],
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
            a(href: appHome, classes: 'ds-button ds-button-primary', [
              .text('Criar minha família'),
            ]),
            a(href: appHome, classes: 'ds-button ds-button-ghost', [
              .text('Entrar'),
            ]),
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
      ]),
      section(classes: 'section faq', attributes: const {'id': 'faq'}, [
        p(classes: 'eyebrow', [.text('Perguntas frequentes')]),
        h2([.text('Antes de abrir a porta, tire suas dúvidas.')]),
        div(classes: 'feature-list', [
          _faq(
            'Como começo?',
            'Crie sua conta com nome, email e senha. Em poucos passos o espaço da sua família está pronto.',
          ),
          _faq(
            'Outras famílias veem meus dados?',
            'Não. Cada família tem um ambiente isolado; membros de outras famílias não acessam suas memórias, arquivos ou localização.',
          ),
          _faq(
            'Posso participar de mais de uma família?',
            'Sim. A mesma conta pode participar de mais de uma família e alternar entre elas sem criar outra conta.',
          ),
          _faq(
            'Quem decide compartilhar a localização?',
            'Cada pessoa decide individualmente se compartilha a própria localização. O ajuste fica em Perfil → Preferências → Localização.',
          ),
        ]),
      ]),
      section(classes: 'section cta', [
        div([
          p(classes: 'eyebrow', [.text('Comece do seu jeito')]),
          h2([.text('Abra a porta da casa digital da sua família.')]),
        ]),
        div(classes: 'actions', [
          a(href: appHome, classes: 'ds-button ds-button-primary', [
            .text('Criar minha família'),
          ]),
        ]),
      ]),
    ]),
  );

  Component _memory(String date, String title, String body) =>
      article(classes: 'memory ds-card', [
        small([.text(date)]),
        strong([.text(title)]),
        p([.text(body)]),
      ]);

  Component _feature(String title, String body) => article(classes: 'feature', [
    h3([.text(title)]),
    p([.text(body)]),
  ]);

  Component _faq(String question, String answer) => article(classes: 'feature', [
    h3([.text(question)]),
    p([.text(answer)]),
  ]);
}
