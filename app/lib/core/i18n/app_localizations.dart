import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocaleOption {
  const AppLocaleOption({
    required this.locale,
    required this.nativeLabel,
    required this.productName,
  });

  final Locale locale;
  final String nativeLabel;
  final String productName;
}

class LocaleController extends ChangeNotifier {
  LocaleController()
      : _locale = AppLocalizations.resolveLocale(
          ui.PlatformDispatcher.instance.locale,
        );

  static const _storageKey = 'app.locale';

  Locale _locale;

  Locale get locale => _locale;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored == null || stored.isEmpty) return;
    _setLocale(AppLocalizations.localeFromCode(stored), persist: false);
  }

  Future<void> setLocale(Locale locale) async {
    final resolved = AppLocalizations.resolveLocale(locale);
    _setLocale(resolved, persist: true);
  }

  void _setLocale(Locale locale, {required bool persist}) {
    if (_locale.languageCode == locale.languageCode &&
        _locale.countryCode == locale.countryCode) {
      return;
    }
    _locale = locale;
    notifyListeners();
    if (persist) {
      SharedPreferences.getInstance().then(
        (prefs) => prefs.setString(
          _storageKey,
          AppLocalizations.storageCode(locale),
        ),
      );
    }
  }
}

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[
    Locale('pt', 'BR'),
    Locale('en'),
    Locale('es'),
  ];

  static const options = <AppLocaleOption>[
    AppLocaleOption(
      locale: Locale('pt', 'BR'),
      nativeLabel: 'Português',
      productName: 'Nossa Família',
    ),
    AppLocaleOption(
      locale: Locale('en'),
      nativeLabel: 'English',
      productName: 'Our Family',
    ),
    AppLocaleOption(
      locale: Locale('es'),
      nativeLabel: 'Español',
      productName: 'Nuestra Familia',
    ),
  ];

  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(Locale('pt', 'BR'));
  }

  static Locale resolveLocale(Locale? locale) {
    return switch (locale?.languageCode) {
      'en' => const Locale('en'),
      'es' => const Locale('es'),
      _ => const Locale('pt', 'BR'),
    };
  }

  static Locale localeFromCode(String code) {
    final normalized = code.toLowerCase();
    if (normalized.startsWith('en')) return const Locale('en');
    if (normalized.startsWith('es')) return const Locale('es');
    return const Locale('pt', 'BR');
  }

  static String storageCode(Locale locale) {
    return switch (locale.languageCode) {
      'en' => 'en',
      'es' => 'es',
      _ => 'pt-BR',
    };
  }

  String get code => switch (locale.languageCode) {
        'en' => 'en',
        'es' => 'es',
        _ => 'pt',
      };

  String get apiCode => switch (code) {
        'en' => 'en',
        'es' => 'es',
        _ => 'pt-BR',
      };

  String get productName => tr('Nossa Família');

  String tr(String key, {Map<String, Object?> args = const {}}) {
    final value = _translations[code]?[key] ?? key;
    return _format(value, args);
  }

  String monthName(int month) {
    if (month < 1 || month > 12) return '';
    return tr('month.$month');
  }

  String statusLabel(String? status) {
    return switch (status) {
      'active' => tr('Assinatura ativa'),
      'past_due' => tr('Pagamento pendente'),
      'suspended' => tr('Assinatura suspensa'),
      'canceled' => tr('Assinatura cancelada'),
      _ => tr('Aguardando ativação'),
    };
  }

  static String _format(String value, Map<String, Object?> args) {
    var result = value;
    for (final entry in args.entries) {
      result = result.replaceAll('{${entry.key}}', '${entry.value}');
    }
    return result;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture(
      AppLocalizations(AppLocalizations.resolveLocale(locale)),
    );
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String tr(String key, {Map<String, Object?> args = const {}}) {
    return l10n.tr(key, args: args);
  }
}

const _translations = <String, Map<String, String>>{
  'pt': {
    'month.1': 'janeiro',
    'month.2': 'fevereiro',
    'month.3': 'março',
    'month.4': 'abril',
    'month.5': 'maio',
    'month.6': 'junho',
    'month.7': 'julho',
    'month.8': 'agosto',
    'month.9': 'setembro',
    'month.10': 'outubro',
    'month.11': 'novembro',
    'month.12': 'dezembro',
  },
  'en': {
    'Nossa Família': 'Our Family',
    'Voltar': 'Back',
    'Notificações': 'Notifications',
    'Cor e tema': 'Color and theme',
    'Cor': 'Color',
    'Rosa': 'Pink',
    'Azul': 'Blue',
    'Vermelho': 'Red',
    'Modo': 'Mode',
    'Claro': 'Light',
    'Escuro': 'Dark',
    'Modo escuro ativado.': 'Dark mode enabled.',
    'Modo claro ativado.': 'Light mode enabled.',
    'Idioma': 'Language',
    'Português': 'Portuguese',
    'English': 'English',
    'Español': 'Spanish',
    'Salvar': 'Save',
    'Cancelar': 'Cancel',
    'Escolher': 'Choose',
    'Escolher data': 'Choose date',
    'Tentar novamente': 'Try again',
    'Atualizar': 'Refresh',
    'Excluir': 'Delete',
    'Editar': 'Edit',
    'Entrar': 'Sign in',
    'Sair': 'Sign out',
    'Criar conta': 'Create account',
    'Crie seu acesso para participar das memórias.':
        'Create your access to join the memories.',
    'Entre para acessar fotos, perfil e recursos privados.':
        'Sign in to access photos, profile and private features.',
    'Nome': 'Name',
    'Nome da família': 'Family name',
    'Endereço desejado': 'Preferred address',
    'Email': 'Email',
    'Senha': 'Password',
    'Cadastrar': 'Sign up',
    'Já tenho conta': 'I already have an account',
    'Esqueci minha senha': 'I forgot my password',
    'Se o email existir, você receberá instruções.':
        'If the email exists, you will receive instructions.',
    'Painel': 'Dashboard',
    'Início': 'Home',
    'Site': 'Site',
    'Administrar': 'Admin',
    'Plataforma': 'Platform',
    'Memórias': 'Memories',
    'Mais': 'More',
    'Perfil': 'Profile',
    'Chat': 'Chat',
    'Memórias em Fotos': 'Photo Memories',
    'Nossa Playlist': 'Our Playlist',
    'Carta de Amor': 'Love Letter',
    'Nossa Jornada': 'Our Journey',
    'Jogos do Amor': 'Love Games',
    'Listas': 'Lists',
    'Notas': 'Notes',
    'Localização': 'Location',
    'Fotos, vídeos e álbuns da família.': 'Family photos, videos and albums.',
    'Músicas que marcaram nossa história.': 'Songs that marked our story.',
    'Cartas e declarações especiais.': 'Special letters and declarations.',
    'Capítulos e registros da história da família.':
        'Chapters and records from the family story.',
    'Jogos simples para se divertir juntos.':
        'Simple games to have fun together.',
    'Compras, tarefas e combinados.': 'Groceries, tasks and shared plans.',
    'Ideias, lembretes e registros soltos.':
        'Ideas, reminders and loose notes.',
    'Mapa da família e bateria de cada pessoa.':
        'Family map and each person battery.',
    'Mais opções': 'More options',
    'Meu espaço': 'My space',
    'Assinatura, endereço e publicação.':
        'Subscription, address and publishing.',
    'Minha família': 'My family',
    'Ativar assinatura': 'Activate subscription',
    'Gerenciar assinatura': 'Manage subscription',
    'Atualizar situação': 'Refresh status',
    'Identidade do site': 'Site identity',
    'Nome exibido': 'Display name',
    'Endereço do site': 'Site address',
    'Idioma padrão': 'Default language',
    'Salvar alterações': 'Save changes',
    'Site publicado': 'Published site',
    'Seu site está visível para quem possui o link.':
        'Your site is visible to anyone with the link.',
    'Somente você consegue editar e visualizar no painel.':
        'Only you can edit and preview it in the panel.',
    'Abrir meu site': 'Open my site',
    'Assinatura ativa': 'Subscription active',
    'Pagamento pendente': 'Payment pending',
    'Assinatura suspensa': 'Subscription suspended',
    'Assinatura cancelada': 'Subscription canceled',
    'Aguardando ativação': 'Waiting for activation',
    'Não foi possível abrir o pagamento.': 'Could not open the payment page.',
    'Não foi possível abrir o portal da assinatura.':
        'Could not open the subscription portal.',
    'Nova lista': 'New list',
    'Entre para editar as listas da família.':
        'Sign in to edit the family lists.',
    'Compras, tarefas e qualquer combinado da família.':
        'Groceries, tasks and any family plan.',
    'Listas da família': 'Family lists',
    'Crie a primeira lista.': 'Create the first list.',
    '{count} listas organizadas': '{count} organized lists',
    'Nenhuma lista ainda': 'No lists yet',
    'Crie uma lista para compras, tarefas ou combinados.':
        'Create a list for groceries, tasks or shared plans.',
    'Itens': 'Items',
    'Selecione ou crie uma lista.': 'Select or create a list.',
    '{count} pendentes.': '{count} pending.',
    'Excluir lista': 'Delete list',
    'Adicionar item': 'Add item',
    'Escolha uma lista': 'Choose a list',
    'Toque em uma lista acima para ver os itens.':
        'Tap a list above to see its items.',
    'Lista vazia': 'Empty list',
    'Adicione o primeiro item quando quiser.':
        'Add the first item whenever you want.',
    'Escolher lista': 'Choose list',
    'Selecione uma lista': 'Select a list',
    'Selecione qual lista deseja visualizar.':
        'Select which list you want to view.',
    'Esta ação remove a lista e todos os itens dela.':
        'This removes the list and all its items.',
    'Nome da lista': 'List name',
    'Descrição': 'Description',
    'Novo item': 'New item',
    'Item': 'Item',
    'Adicionar': 'Add',
    'Remover': 'Remove',
    'Subir': 'Move up',
    'Descer': 'Move down',
    'Fechar': 'Close',
    'Menu': 'Menu',
    'Menu administrativo': 'Admin menu',
    'Escolha uma área para gerenciar.': 'Choose an area to manage.',
    'Jogos': 'Games',
    'Estatísticas': 'Stats',
    'Home': 'Home',
    'Edite perfil, função e remova acessos quando precisar.':
        'Edit profile, role and remove access when needed.',
    'Crie, edite, envie push e acompanhe agendamentos.':
        'Create, edit, send push and track schedules.',
    'Configure cada jogo separadamente.': 'Configure each game separately.',
    'Veja quantas vezes cada pessoa concluiu os jogos.':
        'See how often each person completed the games.',
    'Cards, visibilidade e carrossel de fotos da tela inicial.':
        'Cards, visibility and photo carousel from the home screen.',
    'Nova': 'New',
    'Agendar': 'Schedule',
    'Enviar push': 'Send push',
    'Nenhuma notificação cadastrada.': 'No notification registered.',
    'Sem texto': 'No text',
    'Falhou': 'Failed',
    'Remover agendamento': 'Remove schedule',
    'Ícone': 'Icon',
    'Frente': 'Forward',
    'Trás': 'Backward',
    'Conta para trás': 'Count backward',
    'Conta para frente': 'Count forward',
    'Carrossel de fotos': 'Photo carousel',
    'Editar carrossel': 'Edit carousel',
    'Cards da Home': 'Home cards',
    'Remover card': 'Remove card',
    'Nova senha': 'New password',
    'Confirmar senha': 'Confirm password',
    'Mostrar senha': 'Show password',
    'Ocultar senha': 'Hide password',
    'Rota ao abrir': 'Route to open',
    'Em 10 min': 'In 10 min',
    'Em 1 hora': 'In 1 hour',
    'Amanhã': 'Tomorrow',
    'Pergunta': 'Question',
    'Correta': 'Correct',
    'Opção {index}': 'Option {index}',
    'Palavra': 'Word',
    'Memória da Família': 'Family Memory',
    'Linha do Amor': 'Love Timeline',
    'Isso ou Aquilo': 'This or That',
    'Mini jogo': 'Mini game',
    'Novo {title}': 'New {title}',
    'Instrução': 'Instruction',
    'Ativo': 'Active',
    'Pares da memória': 'Memory pairs',
    'Passos da linha': 'Timeline steps',
    'Rodadas de escolha': 'Choice rounds',
    'Cada item vira um par no jogo da memória.':
        'Each item becomes a pair in the memory game.',
    'A ordem cadastrada aqui será a ordem correta do jogo.':
        'The order registered here will be the correct game order.',
    'Cada rodada tem uma pergunta e duas opções. Não existe resposta certa.':
        'Each round has one question and two options. There is no right answer.',
    'Cadastre os itens do jogo.': 'Register the game items.',
    'Informe o título do jogo.': 'Enter the game title.',
    'Cadastre pelo menos um item completo.':
        'Register at least one complete item.',
    '{index}. {title}': '{index}. {title}',
    'Par': 'Pair',
    'Passo': 'Step',
    'Rodada': 'Round',
    'Texto do par': 'Pair text',
    'Momento da história': 'Story moment',
    'Opção A': 'Option A',
    'Opção B': 'Option B',
    'Este aparelho ainda não está registrado para receber notificações.':
        'This device is not registered to receive notifications yet.',
    'Nenhuma notificação por enquanto.': 'No notifications yet.',
    'Push ativo': 'Push enabled',
    'Ativar push': 'Enable push',
    'Escreva e edite os textos desta página.':
        'Write and edit this page texts.',
    'Textos publicados para a família.': 'Texts published for the family.',
    'Escrever': 'Write',
    'Nenhum texto escrito ainda.': 'No text written yet.',
    'Ainda não há textos publicados.': 'There are no published texts yet.',
    'Escrever em {title}': 'Write in {title}',
    'Registre um texto especial para aparecer no app.':
        'Write a special text to show in the app.',
    'Título': 'Title',
    'Texto': 'Text',
    'Onde a família está agora e como anda a bateria.':
        'Where the family is now and how the battery is doing.',
    'Nenhuma localização recebida ainda. Crie um local pelo botão acima.':
        'No location received yet. Create a place with the button above.',
    'Locais cadastrados': 'Saved places',
    'Mapa': 'Map',
    'Aguardando localizações.': 'Waiting for locations.',
    '{count} pessoas no mapa.': '{count} people on the map.',
    'Novo local': 'New place',
    'Pessoas': 'People',
    'Aguardando atualizações.': 'Waiting for updates.',
    '{count} localizações recentes.': '{count} recent locations.',
    'Quando alguém abrir o app e permitir localização, aparece aqui.':
        'When someone opens the app and allows location, they appear here.',
    'Editar local': 'Edit place',
    'Arraste o mapa e deixe o marcador no ponto desejado.':
        'Drag the map and place the marker where you want.',
    'Raio em metros': 'Radius in meters',
    'Visitante': 'Guest',
    'Nova conversa': 'New conversation',
    'Nenhuma pessoa encontrada.': 'No person found.',
    'Apagar mensagem?': 'Delete message?',
    'Ela continuará aparecendo como mensagem apagada.':
        'It will keep appearing as a deleted message.',
    'Apagar': 'Delete',
    'Editar mensagem': 'Edit message',
    'Mensagem': 'Message',
    'Conversas': 'Conversations',
    'Todos podem conversar': 'Everyone can chat',
    'Conversa privada': 'Private conversation',
    'Conversa aberta para todos': 'Conversation open to everyone',
    'Conversa entre pessoas logadas': 'Conversation between signed-in people',
    'Nenhuma conversa disponível.': 'No conversation available.',
    'Seu nome': 'Your name',
    'Emojis e figurinhas': 'Emojis and stickers',
    'Enviar imagem': 'Send image',
    'Escreva uma mensagem...': 'Write a message...',
    'Cancelar resposta': 'Cancel reply',
    'Figurinha': 'Sticker',
    'Mídia': 'Media',
    'Mensagem apagada': 'Deleted message',
    'editada': 'edited',
    'Escolha um emoji ou envie uma figurinha.':
        'Choose an emoji or send a sticker.',
    'Emojis': 'Emojis',
    'Figurinhas': 'Stickers',
    'Família': 'Family',
    'Pessoa': 'Person',
    'Escolha uma ação para esta mensagem.':
        'Choose an action for this message.',
    'Responder': 'Reply',
    'Informações': 'Information',
    'Detalhes desta mensagem.': 'Message details.',
    'Enviada por': 'Sent by',
    'Enviada em': 'Sent at',
    'Editada em': 'Edited at',
    'Apagada em': 'Deleted at',
    'Status': 'Status',
    'Visualizada': 'Seen',
    'Enviada': 'Sent',
    'Recebida': 'Received',
    'Conta, avatar e opções do app.': 'Account, avatar and app options.',
    'Sem nome': 'No name',
    'Conta': 'Account',
    'Editar perfil': 'Edit profile',
    'Atualize seu nome e suas informações.':
        'Update your name and your information.',
    'Configurações da família': 'Family settings',
    'Família selecionada': 'Selected family',
    'Trocar família': 'Switch family',
    'Assinatura e publicação': 'Subscription and publishing',
    'Gerencie o plano e o endereço do seu site.':
        'Manage your plan and site address.',
    'Plano, endereço público e disponibilidade do site.':
        'Plan, public address and site availability.',
    'Nome, foto e segurança da sua conta.': 'Name, photo and account security.',
    'Administração da família': 'Family administration',
    'Gerencie usuários, notificações e jogos.':
        'Manage users, notifications and games.',
    'Usuários, jogos, notificações e Home.':
        'Users, games, notifications and Home.',
    'Administração da plataforma': 'Platform administration',
    'Estatísticas, famílias, assinaturas e auditoria.':
        'Stats, families, subscriptions and audit.',
    'Sessão': 'Session',
    'Encerrar sua sessão neste dispositivo.':
        'End your session on this device.',
    'Proprietário': 'Owner',
    'Administrador': 'Administrator',
    'Membro': 'Member',
    'Seu espaço da família': 'Your family space',
    'Entre para acessar memórias, perfil, administração e conversas privadas.':
        'Sign in to access memories, profile, administration and private conversations.',
    'Atualize como seu nome aparece no app.':
        'Update how your name appears in the app.',
    'Quiz do Amor': 'Love Quiz',
    'Jogo de perguntas para brincar juntos.':
        'A question game to play together.',
    'Caça Palavras': 'Word Search',
    'Encontre palavras especiais no tabuleiro.':
        'Find special words on the board.',
    'Escolha para onde seguir.': 'Choose where to go next.',
    'Responda uma pergunta por vez.': 'Answer one question at a time.',
    'Toque na primeira letra e depois na última.':
        'Tap the first letter and then the last one.',
    'Encontre as palavras na horizontal, vertical e diagonal.':
        'Find the words horizontally, vertically and diagonally.',
    'Palavras': 'Words',
    'Novo sorteio': 'New draw',
    'Jogo configurável pelo painel.': 'Game configurable from the panel.',
    'Recomeçar': 'Restart',
    'Comece pelo primeiro momento.': 'Start with the first moment.',
    'Quase! Esse momento vem depois.': 'Almost! That moment comes later.',
    'Você acertou {score} de {total}.': 'You got {score} out of {total} right.',
    'Você escolheu {answered} de {total}.':
        'You chose {answered} out of {total}.',
    'Aqui não tem resposta certa, só preferência.':
        'There is no right answer here, only preference.',
    'Jogar novamente': 'Play again',
    'Usuários, famílias, assinaturas e auditoria.':
        'Users, families, subscriptions and audit.',
    'Painel da família': 'Family dashboard',
    'Gerencie sua conta, publicação e conteúdo.':
        'Manage your account, publishing and content.',
    'bem-vindo': 'welcome',
    'Olá, {name}': 'Hello, {name}',
    'Este é o centro de controle da sua família.':
        'This is your family control center.',
    'Assinatura': 'Subscription',
    'Situação atual da conta': 'Current account status',
    'Publicação': 'Publishing',
    'Online': 'Online',
    'Privado': 'Private',
    'Seu perfil': 'Your profile',
    'Áreas liberadas': 'Enabled areas',
    'Todas': 'All',
    'Recursos acessíveis': 'Accessible features',
    'Acessos rápidos': 'Quick access',
    'Escolha a área que deseja gerenciar.':
        'Choose the area you want to manage.',
    'Abrir site da família': 'Open family site',
    'Veja a experiência e os conteúdos da família.':
        'See the family experience and content.',
    'Plano, endereço e disponibilidade pública.':
        'Plan, address and public availability.',
    'Nome, foto e segurança da conta.': 'Name, photo and account security.',
    'Administrar família': 'Administer family',
    'Usuários, jogos, notificações e página.':
        'Users, games, notifications and page.',
    'Ativa': 'Active',
    'Pendente': 'Pending',
    'Em atraso': 'Overdue',
    'Suspensa': 'Suspended',
    'Cancelada': 'Canceled',
    'Rascunho': 'Draft',
    'Usuários': 'Users',
    'Famílias': 'Families',
    'Assinaturas ativas': 'Active subscriptions',
    'Eventos monitorados': 'Monitored events',
    '+{count} nos últimos 30 dias': '+{count} in the last 30 days',
    '{count} ativas': '{count} active',
    '{count} aguardando pagamento': '{count} waiting for payment',
    'Nas últimas 24 horas': 'In the last 24 hours',
    'Famílias recentes': 'Recent families',
    'Últimos cadastros da plataforma.': 'Latest platform registrations.',
    'Atividade recente': 'Recent activity',
    'Ações relevantes registradas pelo backend.':
        'Relevant actions recorded by the backend.',
    'Nenhuma família cadastrada.': 'No family registered.',
    'Nenhuma atividade registrada.': 'No activity recorded.',
    'Sistema': 'System',
    'Não foi possível carregar a Home.': 'Could not load Home.',
    'Memória removida.': 'Memory removed.',
    'Item removido.': 'Item removed.',
    'Álbuns': 'Albums',
    'Na visão atual': 'In current view',
    'Todos os álbuns': 'All albums',
    'Filtrar por álbum': 'Filter by album',
    'Escolher álbum': 'Choose album',
    'Filtre as memórias pelo álbum desejado.':
        'Filter memories by the desired album.',
    '{count} memórias': '{count} memories',
    '{title} ainda está vazio.': '{title} is still empty.',
    'Nenhuma memória nesse álbum.': 'No memory in this album.',
    'Sem descrição.': 'No description.',
    'Artista não informado': 'Artist not informed',
    'Link do Spotify salvo': 'Spotify link saved',
    'Sem link do Spotify': 'No Spotify link',
    'PARA MEU AMOR': 'TO MY LOVE',
    'Uma carta esperando palavras de amor.':
        'A letter waiting for words of love.',
    'Abrir carta': 'Open letter',
    'Nota sem conteúdo.': 'Note without content.',
    'Abrir nota': 'Open note',
    'Adicione uma descrição...': 'Add a description...',
    'Vídeo': 'Video',
    'Foto': 'Photo',
    'Novo item em {title}': 'New item in {title}',
    'Editar {title}': 'Edit {title}',
    'Preencha as informações e salve a nota.':
        'Fill in the information and save the note.',
    'Preencha as informações e salve a lembrança.':
        'Fill in the information and save the memory.',
    'Título ou URL': 'Title or URL',
    'Conteúdo': 'Content',
    'Texto / artista': 'Text / artist',
    'Extra': 'Extra',
    'Foto da galeria': 'Photo from gallery',
    'Vídeo da galeria': 'Video from gallery',
    'Adicionar memória': 'Add memory',
    'Editar memória': 'Edit memory',
    'Escolha a mídia, organize por álbum e marque a data pelo calendário.':
        'Choose the media, organize it by album and mark the date on the calendar.',
    'Escolher foto ou vídeo': 'Choose photo or video',
    'Álbum': 'Album',
    'Data da memória': 'Memory date',
    'Com todo o meu amor,': 'With all my love,',
    'Nota': 'Note',
    'Playlist do Nosso Amor': 'Our Love Playlist',
    'Cartas de Amor': 'Love Letters',
    'Nossa Galeria de Memórias': 'Our Memory Gallery',
    'Cada música conta uma história nossa. Uma melodia que nos faz sorrir, dançar e reviver momentos especiais do nosso amor.':
        'Each song tells our story. A melody that makes us smile, dance and relive special moments of our love.',
    'Um espaço especial onde guardo todas as minhas declarações de amor para você. Cada carta é um pedacinho do meu coração transformado em palavras.':
        'A special space where I keep all my declarations of love for you. Each letter is a piece of my heart turned into words.',
    'Notas livres para guardar ideias, lembretes e detalhes importantes da família.':
        'Free notes for ideas, reminders and important family details.',
    'Adicionar Nova Música': 'Add New Song',
    'Escrever Nova Carta': 'Write New Letter',
    'Nova Nota': 'New Note',
    'Adicionar Memória': 'Add Memory',
    'Amor, memórias e pequenos milagres do caminho.':
        'Love, memories and little miracles along the way.',
    'Amor, memórias e pequenos milagres do nosso caminho.':
        'Love, memories and little miracles of our path.',
    'Nossas fotos': 'Our photos',
    'Anos': 'Years',
    'Meses': 'Months',
    'Dias': 'Days',
    'Faltam': 'Remaining',
    'Já se passaram': 'Already passed',
    '{prefix} {days} dias': '{prefix} {days} days',
    '{day} de {month} de {year}': '{month} {day}, {year}',
    'month.1': 'January',
    'month.2': 'February',
    'month.3': 'March',
    'month.4': 'April',
    'month.5': 'May',
    'month.6': 'June',
    'month.7': 'July',
    'month.8': 'August',
    'month.9': 'September',
    'month.10': 'October',
    'month.11': 'November',
    'month.12': 'December',
  },
  'es': {
    'Nossa Família': 'Nuestra Familia',
    'Voltar': 'Volver',
    'Notificações': 'Notificaciones',
    'Cor e tema': 'Color y tema',
    'Cor': 'Color',
    'Rosa': 'Rosa',
    'Azul': 'Azul',
    'Vermelho': 'Rojo',
    'Modo': 'Modo',
    'Claro': 'Claro',
    'Escuro': 'Oscuro',
    'Modo escuro ativado.': 'Modo oscuro activado.',
    'Modo claro ativado.': 'Modo claro activado.',
    'Idioma': 'Idioma',
    'Português': 'Portugués',
    'English': 'Inglés',
    'Español': 'Español',
    'Salvar': 'Guardar',
    'Cancelar': 'Cancelar',
    'Escolher': 'Elegir',
    'Escolher data': 'Elegir fecha',
    'Tentar novamente': 'Intentar nuevamente',
    'Atualizar': 'Actualizar',
    'Excluir': 'Eliminar',
    'Editar': 'Editar',
    'Entrar': 'Entrar',
    'Sair': 'Salir',
    'Criar conta': 'Crear cuenta',
    'Crie seu acesso para participar das memórias.':
        'Crea tu acceso para participar en los recuerdos.',
    'Entre para acessar fotos, perfil e recursos privados.':
        'Entra para acceder a fotos, perfil y recursos privados.',
    'Nome': 'Nombre',
    'Nome da família': 'Nombre de la familia',
    'Endereço desejado': 'Dirección deseada',
    'Email': 'Email',
    'Senha': 'Contraseña',
    'Cadastrar': 'Registrarse',
    'Já tenho conta': 'Ya tengo cuenta',
    'Esqueci minha senha': 'Olvidé mi contraseña',
    'Se o email existir, você receberá instruções.':
        'Si el email existe, recibirás instrucciones.',
    'Painel': 'Panel',
    'Início': 'Inicio',
    'Site': 'Sitio',
    'Administrar': 'Administrar',
    'Plataforma': 'Plataforma',
    'Memórias': 'Recuerdos',
    'Mais': 'Más',
    'Perfil': 'Perfil',
    'Chat': 'Chat',
    'Memórias em Fotos': 'Recuerdos en fotos',
    'Nossa Playlist': 'Nuestra playlist',
    'Carta de Amor': 'Carta de amor',
    'Nossa Jornada': 'Nuestro camino',
    'Jogos do Amor': 'Juegos del amor',
    'Listas': 'Listas',
    'Notas': 'Notas',
    'Localização': 'Ubicación',
    'Fotos, vídeos e álbuns da família.': 'Fotos, videos y álbumes familiares.',
    'Músicas que marcaram nossa história.':
        'Canciones que marcaron nuestra historia.',
    'Cartas e declarações especiais.': 'Cartas y declaraciones especiales.',
    'Capítulos e registros da história da família.':
        'Capítulos y registros de la historia familiar.',
    'Jogos simples para se divertir juntos.':
        'Juegos simples para divertirse juntos.',
    'Compras, tarefas e combinados.': 'Compras, tareas y acuerdos.',
    'Ideias, lembretes e registros soltos.':
        'Ideas, recordatorios y notas sueltas.',
    'Mapa da família e bateria de cada pessoa.':
        'Mapa familiar y batería de cada persona.',
    'Mais opções': 'Más opciones',
    'Meu espaço': 'Mi espacio',
    'Assinatura, endereço e publicação.':
        'Suscripción, dirección y publicación.',
    'Minha família': 'Mi familia',
    'Ativar assinatura': 'Activar suscripción',
    'Gerenciar assinatura': 'Gestionar suscripción',
    'Atualizar situação': 'Actualizar estado',
    'Identidade do site': 'Identidad del sitio',
    'Nome exibido': 'Nombre visible',
    'Endereço do site': 'Dirección del sitio',
    'Idioma padrão': 'Idioma predeterminado',
    'Salvar alterações': 'Guardar cambios',
    'Site publicado': 'Sitio publicado',
    'Seu site está visível para quem possui o link.':
        'Tu sitio está visible para quien tenga el enlace.',
    'Somente você consegue editar e visualizar no painel.':
        'Solo tú puedes editarlo y verlo en el panel.',
    'Abrir meu site': 'Abrir mi sitio',
    'Assinatura ativa': 'Suscripción activa',
    'Pagamento pendente': 'Pago pendiente',
    'Assinatura suspensa': 'Suscripción suspendida',
    'Assinatura cancelada': 'Suscripción cancelada',
    'Aguardando ativação': 'Esperando activación',
    'Não foi possível abrir o pagamento.': 'No fue posible abrir el pago.',
    'Não foi possível abrir o portal da assinatura.':
        'No fue posible abrir el portal de la suscripción.',
    'Nova lista': 'Nueva lista',
    'Entre para editar as listas da família.':
        'Entra para editar las listas de la familia.',
    'Compras, tarefas e qualquer combinado da família.':
        'Compras, tareas y cualquier acuerdo familiar.',
    'Listas da família': 'Listas familiares',
    'Crie a primeira lista.': 'Crea la primera lista.',
    '{count} listas organizadas': '{count} listas organizadas',
    'Nenhuma lista ainda': 'Todavía no hay listas',
    'Crie uma lista para compras, tarefas ou combinados.':
        'Crea una lista para compras, tareas o acuerdos.',
    'Itens': 'Ítems',
    'Selecione ou crie uma lista.': 'Selecciona o crea una lista.',
    '{count} pendentes.': '{count} pendientes.',
    'Excluir lista': 'Eliminar lista',
    'Adicionar item': 'Agregar ítem',
    'Escolha uma lista': 'Elige una lista',
    'Toque em uma lista acima para ver os itens.':
        'Toca una lista arriba para ver los ítems.',
    'Lista vazia': 'Lista vacía',
    'Adicione o primeiro item quando quiser.':
        'Agrega el primer ítem cuando quieras.',
    'Escolher lista': 'Elegir lista',
    'Selecione uma lista': 'Selecciona una lista',
    'Selecione qual lista deseja visualizar.':
        'Selecciona qué lista quieres ver.',
    'Esta ação remove a lista e todos os itens dela.':
        'Esta acción elimina la lista y todos sus ítems.',
    'Nome da lista': 'Nombre de la lista',
    'Descrição': 'Descripción',
    'Novo item': 'Nuevo ítem',
    'Item': 'Ítem',
    'Adicionar': 'Agregar',
    'Remover': 'Eliminar',
    'Subir': 'Subir',
    'Descer': 'Bajar',
    'Fechar': 'Cerrar',
    'Menu': 'Menú',
    'Menu administrativo': 'Menú administrativo',
    'Escolha uma área para gerenciar.': 'Elige un área para gestionar.',
    'Jogos': 'Juegos',
    'Estatísticas': 'Estadísticas',
    'Home': 'Home',
    'Edite perfil, função e remova acessos quando precisar.':
        'Edita perfil, función y elimina accesos cuando haga falta.',
    'Crie, edite, envie push e acompanhe agendamentos.':
        'Crea, edita, envía push y acompaña programaciones.',
    'Configure cada jogo separadamente.': 'Configura cada juego por separado.',
    'Veja quantas vezes cada pessoa concluiu os jogos.':
        'Ve cuántas veces cada persona completó los juegos.',
    'Cards, visibilidade e carrossel de fotos da tela inicial.':
        'Cards, visibilidad y carrusel de fotos de la pantalla inicial.',
    'Nova': 'Nueva',
    'Agendar': 'Programar',
    'Enviar push': 'Enviar push',
    'Nenhuma notificação cadastrada.': 'No hay notificaciones registradas.',
    'Sem texto': 'Sin texto',
    'Falhou': 'Falló',
    'Remover agendamento': 'Eliminar programación',
    'Ícone': 'Ícono',
    'Frente': 'Adelante',
    'Trás': 'Atrás',
    'Conta para trás': 'Cuenta regresiva',
    'Conta para frente': 'Cuenta hacia adelante',
    'Carrossel de fotos': 'Carrusel de fotos',
    'Editar carrossel': 'Editar carrusel',
    'Cards da Home': 'Cards de la Home',
    'Remover card': 'Eliminar card',
    'Nova senha': 'Nueva contraseña',
    'Confirmar senha': 'Confirmar contraseña',
    'Mostrar senha': 'Mostrar contraseña',
    'Ocultar senha': 'Ocultar contraseña',
    'Rota ao abrir': 'Ruta al abrir',
    'Em 10 min': 'En 10 min',
    'Em 1 hora': 'En 1 hora',
    'Amanhã': 'Mañana',
    'Pergunta': 'Pregunta',
    'Correta': 'Correcta',
    'Opção {index}': 'Opción {index}',
    'Palavra': 'Palabra',
    'Memória da Família': 'Memoria familiar',
    'Linha do Amor': 'Línea del amor',
    'Isso ou Aquilo': 'Esto o aquello',
    'Mini jogo': 'Minijuego',
    'Novo {title}': 'Nuevo {title}',
    'Instrução': 'Instrucción',
    'Ativo': 'Activo',
    'Pares da memória': 'Pares de memoria',
    'Passos da linha': 'Pasos de la línea',
    'Rodadas de escolha': 'Rondas de elección',
    'Cada item vira um par no jogo da memória.':
        'Cada ítem se convierte en un par en el juego de memoria.',
    'A ordem cadastrada aqui será a ordem correta do jogo.':
        'El orden registrado aquí será el orden correcto del juego.',
    'Cada rodada tem uma pergunta e duas opções. Não existe resposta certa.':
        'Cada ronda tiene una pregunta y dos opciones. No hay respuesta correcta.',
    'Cadastre os itens do jogo.': 'Registra los ítems del juego.',
    'Informe o título do jogo.': 'Informa el título del juego.',
    'Cadastre pelo menos um item completo.':
        'Registra al menos un ítem completo.',
    '{index}. {title}': '{index}. {title}',
    'Par': 'Par',
    'Passo': 'Paso',
    'Rodada': 'Ronda',
    'Texto do par': 'Texto del par',
    'Momento da história': 'Momento de la historia',
    'Opção A': 'Opción A',
    'Opção B': 'Opción B',
    'Este aparelho ainda não está registrado para receber notificações.':
        'Este dispositivo todavía no está registrado para recibir notificaciones.',
    'Nenhuma notificação por enquanto.': 'No hay notificaciones por ahora.',
    'Push ativo': 'Push activo',
    'Ativar push': 'Activar push',
    'Escreva e edite os textos desta página.':
        'Escribe y edita los textos de esta página.',
    'Textos publicados para a família.': 'Textos publicados para la familia.',
    'Escrever': 'Escribir',
    'Nenhum texto escrito ainda.': 'Todavía no hay textos escritos.',
    'Ainda não há textos publicados.': 'Todavía no hay textos publicados.',
    'Escrever em {title}': 'Escribir en {title}',
    'Registre um texto especial para aparecer no app.':
        'Registra un texto especial para aparecer en la app.',
    'Título': 'Título',
    'Texto': 'Texto',
    'Onde a família está agora e como anda a bateria.':
        'Dónde está la familia ahora y cómo va la batería.',
    'Nenhuma localização recebida ainda. Crie um local pelo botão acima.':
        'Todavía no se recibió ubicación. Crea un lugar con el botón de arriba.',
    'Locais cadastrados': 'Lugares guardados',
    'Mapa': 'Mapa',
    'Aguardando localizações.': 'Esperando ubicaciones.',
    '{count} pessoas no mapa.': '{count} personas en el mapa.',
    'Novo local': 'Nuevo lugar',
    'Pessoas': 'Personas',
    'Aguardando atualizações.': 'Esperando actualizaciones.',
    '{count} localizações recentes.': '{count} ubicaciones recientes.',
    'Quando alguém abrir o app e permitir localização, aparece aqui.':
        'Cuando alguien abra la app y permita ubicación, aparecerá aquí.',
    'Editar local': 'Editar lugar',
    'Arraste o mapa e deixe o marcador no ponto desejado.':
        'Arrastra el mapa y deja el marcador en el punto deseado.',
    'Raio em metros': 'Radio en metros',
    'Visitante': 'Visitante',
    'Nova conversa': 'Nueva conversación',
    'Nenhuma pessoa encontrada.': 'No se encontró ninguna persona.',
    'Apagar mensagem?': '¿Eliminar mensaje?',
    'Ela continuará aparecendo como mensagem apagada.':
        'Seguirá apareciendo como mensaje eliminado.',
    'Apagar': 'Eliminar',
    'Editar mensagem': 'Editar mensaje',
    'Mensagem': 'Mensaje',
    'Conversas': 'Conversaciones',
    'Todos podem conversar': 'Todos pueden conversar',
    'Conversa privada': 'Conversación privada',
    'Conversa aberta para todos': 'Conversación abierta para todos',
    'Conversa entre pessoas logadas': 'Conversación entre personas conectadas',
    'Nenhuma conversa disponível.': 'No hay conversaciones disponibles.',
    'Seu nome': 'Tu nombre',
    'Emojis e figurinhas': 'Emojis y stickers',
    'Enviar imagem': 'Enviar imagen',
    'Escreva uma mensagem...': 'Escribe un mensaje...',
    'Cancelar resposta': 'Cancelar respuesta',
    'Figurinha': 'Sticker',
    'Mídia': 'Medio',
    'Mensagem apagada': 'Mensaje eliminado',
    'editada': 'editada',
    'Escolha um emoji ou envie uma figurinha.':
        'Elige un emoji o envía un sticker.',
    'Emojis': 'Emojis',
    'Figurinhas': 'Stickers',
    'Família': 'Familia',
    'Pessoa': 'Persona',
    'Escolha uma ação para esta mensagem.':
        'Elige una acción para este mensaje.',
    'Responder': 'Responder',
    'Informações': 'Información',
    'Detalhes desta mensagem.': 'Detalles de este mensaje.',
    'Enviada por': 'Enviada por',
    'Enviada em': 'Enviada el',
    'Editada em': 'Editada el',
    'Apagada em': 'Eliminada el',
    'Status': 'Estado',
    'Visualizada': 'Vista',
    'Enviada': 'Enviada',
    'Recebida': 'Recibida',
    'Conta, avatar e opções do app.': 'Cuenta, avatar y opciones de la app.',
    'Sem nome': 'Sin nombre',
    'Conta': 'Cuenta',
    'Editar perfil': 'Editar perfil',
    'Atualize seu nome e suas informações.':
        'Actualiza tu nombre y tu información.',
    'Configurações da família': 'Configuración familiar',
    'Família selecionada': 'Familia seleccionada',
    'Trocar família': 'Cambiar familia',
    'Assinatura e publicação': 'Suscripción y publicación',
    'Gerencie o plano e o endereço do seu site.':
        'Gestiona el plan y la dirección de tu sitio.',
    'Plano, endereço público e disponibilidade do site.':
        'Plan, dirección pública y disponibilidad del sitio.',
    'Nome, foto e segurança da sua conta.':
        'Nombre, foto y seguridad de tu cuenta.',
    'Administração da família': 'Administración familiar',
    'Gerencie usuários, notificações e jogos.':
        'Gestiona usuarios, notificaciones y juegos.',
    'Usuários, jogos, notificações e Home.':
        'Usuarios, juegos, notificaciones y Home.',
    'Administração da plataforma': 'Administración de la plataforma',
    'Estatísticas, famílias, assinaturas e auditoria.':
        'Estadísticas, familias, suscripciones y auditoría.',
    'Sessão': 'Sesión',
    'Encerrar sua sessão neste dispositivo.':
        'Cerrar tu sesión en este dispositivo.',
    'Proprietário': 'Propietario',
    'Administrador': 'Administrador',
    'Membro': 'Miembro',
    'Seu espaço da família': 'Tu espacio familiar',
    'Entre para acessar memórias, perfil, administração e conversas privadas.':
        'Entra para acceder a recuerdos, perfil, administración y conversaciones privadas.',
    'Atualize como seu nome aparece no app.':
        'Actualiza cómo aparece tu nombre en la app.',
    'Quiz do Amor': 'Quiz del amor',
    'Jogo de perguntas para brincar juntos.':
        'Juego de preguntas para jugar juntos.',
    'Caça Palavras': 'Sopa de letras',
    'Encontre palavras especiais no tabuleiro.':
        'Encuentra palabras especiales en el tablero.',
    'Escolha para onde seguir.': 'Elige adónde seguir.',
    'Responda uma pergunta por vez.': 'Responde una pregunta a la vez.',
    'Toque na primeira letra e depois na última.':
        'Toca la primera letra y luego la última.',
    'Encontre as palavras na horizontal, vertical e diagonal.':
        'Encuentra las palabras en horizontal, vertical y diagonal.',
    'Palavras': 'Palabras',
    'Novo sorteio': 'Nuevo sorteo',
    'Jogo configurável pelo painel.': 'Juego configurable desde el panel.',
    'Recomeçar': 'Reiniciar',
    'Comece pelo primeiro momento.': 'Empieza por el primer momento.',
    'Quase! Esse momento vem depois.': '¡Casi! Ese momento viene después.',
    'Você acertou {score} de {total}.': 'Acertaste {score} de {total}.',
    'Você escolheu {answered} de {total}.': 'Elegiste {answered} de {total}.',
    'Aqui não tem resposta certa, só preferência.':
        'Aquí no hay respuesta correcta, solo preferencia.',
    'Jogar novamente': 'Jugar de nuevo',
    'Usuários, famílias, assinaturas e auditoria.':
        'Usuarios, familias, suscripciones y auditoría.',
    'Painel da família': 'Panel familiar',
    'Gerencie sua conta, publicação e conteúdo.':
        'Gestiona tu cuenta, publicación y contenido.',
    'bem-vindo': 'bienvenido',
    'Olá, {name}': 'Hola, {name}',
    'Este é o centro de controle da sua família.':
        'Este es el centro de control de tu familia.',
    'Assinatura': 'Suscripción',
    'Situação atual da conta': 'Estado actual de la cuenta',
    'Publicação': 'Publicación',
    'Online': 'En línea',
    'Privado': 'Privado',
    'Seu perfil': 'Tu perfil',
    'Áreas liberadas': 'Áreas habilitadas',
    'Todas': 'Todas',
    'Recursos acessíveis': 'Recursos accesibles',
    'Acessos rápidos': 'Accesos rápidos',
    'Escolha a área que deseja gerenciar.':
        'Elige el área que quieres gestionar.',
    'Abrir site da família': 'Abrir sitio familiar',
    'Veja a experiência e os conteúdos da família.':
        'Ve la experiencia y los contenidos de la familia.',
    'Plano, endereço e disponibilidade pública.':
        'Plan, dirección y disponibilidad pública.',
    'Nome, foto e segurança da conta.':
        'Nombre, foto y seguridad de la cuenta.',
    'Administrar família': 'Administrar familia',
    'Usuários, jogos, notificações e página.':
        'Usuarios, juegos, notificaciones y página.',
    'Ativa': 'Activa',
    'Pendente': 'Pendiente',
    'Em atraso': 'Atrasada',
    'Suspensa': 'Suspendida',
    'Cancelada': 'Cancelada',
    'Rascunho': 'Borrador',
    'Usuários': 'Usuarios',
    'Famílias': 'Familias',
    'Assinaturas ativas': 'Suscripciones activas',
    'Eventos monitorados': 'Eventos monitoreados',
    '+{count} nos últimos 30 dias': '+{count} en los últimos 30 días',
    '{count} ativas': '{count} activas',
    '{count} aguardando pagamento': '{count} esperando pago',
    'Nas últimas 24 horas': 'En las últimas 24 horas',
    'Famílias recentes': 'Familias recientes',
    'Últimos cadastros da plataforma.': 'Últimos registros de la plataforma.',
    'Atividade recente': 'Actividad reciente',
    'Ações relevantes registradas pelo backend.':
        'Acciones relevantes registradas por el backend.',
    'Nenhuma família cadastrada.': 'No hay familias registradas.',
    'Nenhuma atividade registrada.': 'No hay actividad registrada.',
    'Sistema': 'Sistema',
    'Não foi possível carregar a Home.': 'No fue posible cargar la Home.',
    'Memória removida.': 'Recuerdo eliminado.',
    'Item removido.': 'Ítem eliminado.',
    'Álbuns': 'Álbumes',
    'Na visão atual': 'En la vista actual',
    'Todos os álbuns': 'Todos los álbumes',
    'Filtrar por álbum': 'Filtrar por álbum',
    'Escolher álbum': 'Elegir álbum',
    'Filtre as memórias pelo álbum desejado.':
        'Filtra los recuerdos por el álbum deseado.',
    '{count} memórias': '{count} recuerdos',
    '{title} ainda está vazio.': '{title} todavía está vacío.',
    'Nenhuma memória nesse álbum.': 'No hay recuerdos en este álbum.',
    'Sem descrição.': 'Sin descripción.',
    'Artista não informado': 'Artista no informado',
    'Link do Spotify salvo': 'Enlace de Spotify guardado',
    'Sem link do Spotify': 'Sin enlace de Spotify',
    'PARA MEU AMOR': 'PARA MI AMOR',
    'Uma carta esperando palavras de amor.':
        'Una carta esperando palabras de amor.',
    'Abrir carta': 'Abrir carta',
    'Nota sem conteúdo.': 'Nota sin contenido.',
    'Abrir nota': 'Abrir nota',
    'Adicione uma descrição...': 'Agrega una descripción...',
    'Vídeo': 'Video',
    'Foto': 'Foto',
    'Novo item em {title}': 'Nuevo ítem en {title}',
    'Editar {title}': 'Editar {title}',
    'Preencha as informações e salve a nota.':
        'Completa la información y guarda la nota.',
    'Preencha as informações e salve a lembrança.':
        'Completa la información y guarda el recuerdo.',
    'Título ou URL': 'Título o URL',
    'Conteúdo': 'Contenido',
    'Texto / artista': 'Texto / artista',
    'Extra': 'Extra',
    'Foto da galeria': 'Foto de la galería',
    'Vídeo da galeria': 'Video de la galería',
    'Adicionar memória': 'Agregar recuerdo',
    'Editar memória': 'Editar recuerdo',
    'Escolha a mídia, organize por álbum e marque a data pelo calendário.':
        'Elige el medio, organízalo por álbum y marca la fecha en el calendario.',
    'Escolher foto ou vídeo': 'Elegir foto o video',
    'Álbum': 'Álbum',
    'Data da memória': 'Fecha del recuerdo',
    'Com todo o meu amor,': 'Con todo mi amor,',
    'Nota': 'Nota',
    'Playlist do Nosso Amor': 'Playlist de nuestro amor',
    'Cartas de Amor': 'Cartas de amor',
    'Nossa Galeria de Memórias': 'Nuestra galería de recuerdos',
    'Cada música conta uma história nossa. Uma melodia que nos faz sorrir, dançar e reviver momentos especiais do nosso amor.':
        'Cada canción cuenta nuestra historia. Una melodía que nos hace sonreír, bailar y revivir momentos especiales de nuestro amor.',
    'Um espaço especial onde guardo todas as minhas declarações de amor para você. Cada carta é um pedacinho do meu coração transformado em palavras.':
        'Un espacio especial donde guardo todas mis declaraciones de amor para ti. Cada carta es un pedacito de mi corazón convertido en palabras.',
    'Notas livres para guardar ideias, lembretes e detalhes importantes da família.':
        'Notas libres para guardar ideas, recordatorios y detalles importantes de la familia.',
    'Adicionar Nova Música': 'Agregar nueva canción',
    'Escrever Nova Carta': 'Escribir nueva carta',
    'Nova Nota': 'Nueva nota',
    'Adicionar Memória': 'Agregar recuerdo',
    'Amor, memórias e pequenos milagres do caminho.':
        'Amor, recuerdos y pequeños milagros del camino.',
    'Amor, memórias e pequenos milagres do nosso caminho.':
        'Amor, recuerdos y pequeños milagros de nuestro camino.',
    'Nossas fotos': 'Nuestras fotos',
    'Anos': 'Años',
    'Meses': 'Meses',
    'Dias': 'Días',
    'Faltam': 'Faltan',
    'Já se passaram': 'Ya pasaron',
    '{prefix} {days} dias': '{prefix} {days} días',
    '{day} de {month} de {year}': '{day} de {month} de {year}',
    'month.1': 'enero',
    'month.2': 'febrero',
    'month.3': 'marzo',
    'month.4': 'abril',
    'month.5': 'mayo',
    'month.6': 'junio',
    'month.7': 'julio',
    'month.8': 'agosto',
    'month.9': 'septiembre',
    'month.10': 'octubre',
    'month.11': 'noviembre',
    'month.12': 'diciembre',
  },
};
