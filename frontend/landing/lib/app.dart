import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'pages/content_page.dart';
import 'pages/home_page.dart';
import 'pages/register_page.dart';

class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) => Router(
    routes: [
      Route(path: '/', builder: (_, _) => const HomePage()),
      Route(
        path: '/recursos',
        builder: (_, _) => const ContentPage(
          path: '/recursos',
          eyebrow: 'Tudo em um só lugar',
          title: 'Recursos para guardar e viver a história de vocês.',
          description:
              'Conheça os recursos do Nossa Família para memórias, rotina, conversa e segurança.',
          sections: [
            (
              'Memórias sem feed',
              'Fotos, vídeos, cartas e a história familiar ficam organizados no espaço privado de vocês.',
            ),
            (
              'Rotina compartilhada',
              'Listas, notas e lembretes ajudam a coordenar a casa sem espalhar tudo em vários aplicativos.',
            ),
            (
              'Conexão cotidiana',
              'Chat, jogos, músicas e pequenos rituais criam um lugar dedicado à família.',
            ),
            (
              'Identidade própria',
              'A família escolhe sua cor principal e tipografia, com contraste calculado automaticamente.',
            ),
          ],
        ),
      ),
      Route(
        path: '/como-funciona',
        builder: (_, _) => const ContentPage(
          path: '/como-funciona',
          eyebrow: 'Simples desde a porta',
          title: 'Do celular ao espaço da família em poucos passos.',
          description:
              'Veja como criar uma família, confirmar o celular e convidar pessoas no Nossa Família.',
          sections: [
            (
              '1. Confirme seu celular',
              'Informe o número, receba um código por WhatsApp ou SMS e entre sem criar senha.',
            ),
            (
              '2. A família já está pronta',
              'Criamos um espaço privado automaticamente; nome, endereço, cor e fonte podem ser personalizados depois no painel.',
            ),
            (
              '3. Convide quem faz parte',
              'Envie o convite ao celular e defina papel e permissões de cada pessoa.',
            ),
            (
              '4. Comecem a usar',
              'Memórias, listas, cartas, localização e conversas já ficam isoladas no ambiente da família.',
            ),
          ],
        ),
      ),
      Route(
        path: '/seguranca',
        builder: (_, _) => const ContentPage(
          path: '/seguranca',
          eyebrow: 'Privado desde o começo',
          title: 'A família vê a família. A plataforma vê somente a operação.',
          description:
              'Entenda como o Nossa Família protege conteúdo, arquivos, sessões e acesso de cada família.',
          sections: [
            (
              'Isolamento por família',
              'Banco, arquivos, eventos em tempo real e filas carregam o contexto obrigatório da família.',
            ),
            (
              'Mídia privada',
              'Arquivos usam endereços temporários e não são publicados em buckets abertos.',
            ),
            (
              'Acesso sem senha',
              'Códigos curtos expiram em cinco minutos, têm limite de tentativas e só podem ser usados uma vez.',
            ),
            (
              'Administração limitada',
              'A equipe acompanha status, plano e consumo, sem uma tela para navegar pelo conteúdo privado.',
            ),
          ],
        ),
      ),
      Route(
        path: '/faq',
        builder: (_, _) => const ContentPage(
          path: '/faq',
          eyebrow: 'Perguntas frequentes',
          title: 'Antes de abrir a porta, tire suas dúvidas.',
          description:
              'Respostas sobre privacidade, celular, convites, demo e uso do Nossa Família.',
          faq: true,
          sections: [
            (
              'Preciso criar uma senha?',
              'Não. Você entra com um código enviado ao seu WhatsApp ou por SMS.',
            ),
            (
              'Outras famílias veem meus dados?',
              'Não. Cada consulta, arquivo e evento é isolado pelo identificador da família.',
            ),
            (
              'Posso participar de mais de uma família?',
              'Sim. O mesmo celular pode participar de várias famílias e alternar entre elas.',
            ),
            (
              'A demo usa minha localização?',
              'Não. A demonstração bloqueia localização real, uploads, notificações e convites.',
            ),
          ],
        ),
      ),
      Route(
        path: '/privacidade',
        builder: (_, _) => const ContentPage(
          path: '/privacidade',
          eyebrow: 'Política de privacidade',
          title: 'Privacidade explicada sem letras miúdas.',
          description: 'Política de privacidade do Nossa Família.',
          sections: [
            (
              'Dados utilizados',
              'Usamos celular, dados de perfil e o conteúdo que a própria família decide armazenar.',
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
          description: 'Termos de uso do Nossa Família.',
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
              'O código recebido no celular é pessoal e não deve ser compartilhado com terceiros.',
            ),
          ],
        ),
      ),
      Route(path: '/cadastro', builder: (_, _) => const RegisterPage()),
    ],
  );
}
