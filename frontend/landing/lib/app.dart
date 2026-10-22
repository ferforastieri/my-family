import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'pages/content_page.dart';
import 'pages/home_page.dart';

class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) => Router(
    routes: [
      Route(path: '/', builder: (_, _) => const HomePage()),
      Route(
        path: '/privacidade',
        builder: (_, _) => const ContentPage(
          path: '/privacidade',
          eyebrow: 'Política de privacidade',
          title: 'Privacidade explicada sem letras miúdas.',
          description: 'Política de privacidade do Sião.',
          sections: [
            (
              'Dados utilizados',
              'Usamos email, dados de perfil e o conteúdo que a própria família decide armazenar.',
            ),
            (
              'Finalidade',
              'Os dados existem para autenticar pessoas e entregar os recursos privados contratados.',
            ),
            (
              'Controle',
              'Owners administram membros e permissões. Solicitações legais serão atendidas pelos canais oficiais.',
            ),
          ],
        ),
      ),
      Route(
        path: '/termos',
        builder: (_, _) => const ContentPage(
          path: '/termos',
          eyebrow: 'Termos de uso',
          title: 'Um acordo claro para um espaço importante.',
          description: 'Termos de uso do Sião.',
          sections: [
            (
              'Uso responsável',
              'Cada pessoa responde pelo conteúdo que publica e pelos convites que envia.',
            ),
            (
              'Disponibilidade',
              'Podemos realizar manutenção e aplicar limites necessários para manter o serviço seguro.',
            ),
            (
              'Conta e acesso',
              'Sua senha é pessoal e não deve ser compartilhada com terceiros.',
            ),
          ],
        ),
      ),
    ],
  );
}
