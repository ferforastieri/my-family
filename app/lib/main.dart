import 'dart:async';

import 'package:flutter/material.dart';

import 'core/auth/auth_controller.dart';
import 'core/auth/token_store.dart';
import 'core/socket/socket_client.dart';
import 'data/family_repository.dart';
import 'data/models.dart';

const _primary = Color(0xffff69b4);
const _primaryDark = Color(0xffd4488e);
const _bgStart = Color(0xfffff8fa);
const _bgEnd = Color(0xfffff0f5);
const _foreground = Color(0xff26131d);
const _muted = Color(0xff775b6b);
const _border = Color(0xffffdce9);

void main() {
  final socket = SocketClient();
  final auth = AuthController(socket, TokenStore());
  runApp(MyFamilyApp(auth: auth, repository: FamilyRepository(socket)));
  auth.bootstrap();
}

class MyFamilyApp extends StatelessWidget {
  const MyFamilyApp({super.key, required this.auth, required this.repository});

  final AuthController auth;
  final FamilyRepository repository;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: auth,
      builder: (context, _) {
        return MaterialApp(
          title: 'Nossa Familia',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: _primary,
              primary: _primary,
              surface: Colors.white,
            ),
            scaffoldBackgroundColor: _bgStart,
            useMaterial3: true,
            textTheme: ThemeData.light().textTheme.apply(
                  bodyColor: _foreground,
                  displayColor: _foreground,
                ),
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: _foreground,
              surfaceTintColor: Colors.transparent,
            ),
            cardTheme: CardThemeData(
              color: Colors.white.withValues(alpha: .90),
              elevation: 3,
              shadowColor: Color(0x1aff69b4),
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: _border),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          home: auth.loading
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : Shell(auth: auth, repository: repository),
        );
      },
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key, required this.auth, required this.repository});

  final AuthController auth;
  final FamilyRepository repository;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onNavigate: (page) => setState(() => index = page)),
      const StoryPage(),
      const MessagesPage(),
      ResourcePage(title: 'Carta de Amor', resource: 'cartas', repository: widget.repository),
      ResourcePage(title: 'Nossa Playlist', resource: 'musicas', repository: widget.repository),
      ResourcePage(title: 'Memorias em Fotos', resource: 'fotos', repository: widget.repository),
      const GamesPage(),
      ProfilePage(auth: widget.auth),
      if (widget.auth.user?.role == 'admin') AdminPage(auth: widget.auth),
    ];

    final destinations = [
      const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Nosso Início'),
      const NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Nossa Jornada'),
      const NavigationDestination(icon: Icon(Icons.mail_outline), selectedIcon: Icon(Icons.mail), label: 'Palavras do Coração'),
      const NavigationDestination(icon: Icon(Icons.card_giftcard_outlined), selectedIcon: Icon(Icons.card_giftcard), label: 'Carta de Amor'),
      const NavigationDestination(icon: Icon(Icons.music_note_outlined), selectedIcon: Icon(Icons.music_note), label: 'Nossa Playlist'),
      const NavigationDestination(icon: Icon(Icons.photo_outlined), selectedIcon: Icon(Icons.photo), label: 'Memórias em Fotos'),
      const NavigationDestination(icon: Icon(Icons.sports_esports_outlined), selectedIcon: Icon(Icons.sports_esports), label: 'Jogos do Amor'),
      const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
      if (widget.auth.user?.role == 'admin')
        const NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), selectedIcon: Icon(Icons.admin_panel_settings), label: 'Administração'),
    ];

    final selected = index.clamp(0, pages.length - 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 860;
        return Scaffold(
          appBar: AppBar(
            titleSpacing: wide ? 28 : 16,
            title: const Text(
              '💕 Nossa Família',
              style: TextStyle(color: _primary, fontWeight: FontWeight.w900, fontSize: 21),
            ),
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_outlined), tooltip: 'Notificações'),
              if (widget.auth.user == null)
                TextButton.icon(
                  onPressed: _openLogin,
                  icon: const Icon(Icons.account_circle_outlined, size: 20),
                  label: const Text('Entrar'),
                )
              else
                IconButton(onPressed: widget.auth.signOut, icon: const Icon(Icons.logout), tooltip: 'Sair'),
              const SizedBox(width: 14),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(wide ? 58 : 1),
              child: Column(
                children: [
                  const Divider(height: 1, color: _border),
                  if (wide)
                    _TopNavigation(
                      selected: selected,
                      destinations: destinations,
                      onSelected: (value) => setState(() => index = value),
                    ),
                ],
              ),
            ),
          ),
          body: pages[selected],
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: selected,
                  onDestinationSelected: (value) => setState(() => index = value),
                  indicatorColor: _primary.withValues(alpha: .14),
                  backgroundColor: Colors.white,
                  destinations: destinations,
                ),
        );
      },
    );
  }

  void _openLogin() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AuthSheet(auth: widget.auth),
    );
  }
}

class _TopNavigation extends StatelessWidget {
  const _TopNavigation({
    required this.selected,
    required this.destinations,
    required this.onSelected,
  });

  final int selected;
  final List<NavigationDestination> destinations;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 57,
      color: Colors.white,
      alignment: Alignment.center,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < destinations.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: TextButton.icon(
                  onPressed: () => onSelected(i),
                  icon: IconTheme(
                    data: const IconThemeData(size: 19),
                    child: i == selected ? (destinations[i].selectedIcon ?? destinations[i].icon) : destinations[i].icon,
                  ),
                  label: Text(destinations[i].label),
                  style: TextButton.styleFrom(
                    foregroundColor: i == selected ? _primary : _foreground,
                    backgroundColor: i == selected ? _primary.withValues(alpha: .08) : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LoveBackground extends StatelessWidget {
  const LoveBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bgStart, _bgEnd],
        ),
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.size});

  final String text;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: _primary,
        fontFamily: 'serif',
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.1,
      ).copyWith(fontSize: size),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Timer timer;
  late List<CounterInfo> counters;

  @override
  void initState() {
    super.initState();
    counters = _buildCounters();
    timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => counters = _buildCounters()));
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      MenuCardData('Nossa História', 'Descubra como tudo começou e os momentos que nos trouxeram até aqui.', Icons.menu_book, 1),
      MenuCardData('Jogos do Amor', 'Divirta-se com nossos jogos especiais, incluindo o Quiz do Amor.', Icons.sports_esports, 6),
      MenuCardData('Mensagens do Coração', 'Palavras de amor e carinho que compartilhamos.', Icons.mail, 2),
      MenuCardData('Carta de Amor', 'Uma declaração especial do meu coração para você.', Icons.card_giftcard, 3),
      MenuCardData('Uma Flor para Minha Esposa', 'Um jardim especial dedicado à mulher da minha vida.', Icons.local_florist, 2),
    ];

    return LoveBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 38),
        children: [
          const SectionTitle('Para Meu Amor ❤️', size: 38),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 860;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: wide ? 3 : 1,
                childAspectRatio: wide ? 1.25 : 1.65,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: counters.map((counter) => CounterCard(counter)).toList(),
              );
            },
          ),
          const SizedBox(height: 22),
          const Text(
            'Um jardim digital de memórias e amor, onde cada momento representa uma parte especial da nossa história juntos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 16, height: 1.45),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 1100
                  ? 5
                  : constraints.maxWidth >= 760
                      ? 3
                      : constraints.maxWidth >= 520
                          ? 2
                          : 1;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                childAspectRatio: 1.05,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                children: cards
                    .map(
                      (card) => InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => widget.onNavigate(card.page),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  card.title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: _primary,
                                    fontFamily: 'serif',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  card.description,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: _muted, fontSize: 13, height: 1.35),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class MenuCardData {
  const MenuCardData(this.title, this.description, this.icon, this.page);

  final String title;
  final String description;
  final IconData icon;
  final int page;
}

class CounterInfo {
  const CounterInfo({
    required this.title,
    required this.icon,
    required this.date,
    required this.message,
    required this.elapsed,
    required this.colors,
  });

  final String title;
  final String icon;
  final DateTime date;
  final String message;
  final ElapsedTime elapsed;
  final List<Color> colors;
}

class ElapsedTime {
  const ElapsedTime({
    required this.years,
    required this.months,
    required this.days,
    required this.totalDays,
    required this.isFuture,
  });

  final int years;
  final int months;
  final int days;
  final int totalDays;
  final bool isFuture;
}

List<CounterInfo> _buildCounters() {
  return [
    CounterInfo(
      title: 'Começamos a Namorar',
      icon: '💕',
      date: DateTime(2024, 10, 12),
      message: 'Desde o primeiro olhar, sabia que você era especial',
      elapsed: _elapsed(DateTime(2024, 10, 12)),
      colors: const [_primary, _primaryDark],
    ),
    CounterInfo(
      title: 'Nosso Casamento',
      icon: '💍',
      date: DateTime(2025, 4, 15),
      message: 'O dia mais feliz da minha vida ao seu lado',
      elapsed: _elapsed(DateTime(2025, 4, 15)),
      colors: const [Color(0xffff73b9), Color(0xffdf5198)],
    ),
    CounterInfo(
      title: 'Nascimento do Fernando',
      icon: '👶',
      date: DateTime(2026, 6, 1),
      message: 'Nosso maior presente de amor chegando',
      elapsed: _elapsed(DateTime(2026, 6, 1)),
      colors: const [Color(0xffc084fc), Color(0xff9333ea)],
    ),
  ];
}

ElapsedTime _elapsed(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  final isFuture = diff.isNegative;
  final days = diff.inDays.abs();
  return ElapsedTime(
    years: days ~/ 365,
    months: ((days % 365) / 30.44).floor(),
    days: (days % 30.44).floor(),
    totalDays: days,
    isFuture: isFuture,
  );
}

class CounterCard extends StatelessWidget {
  const CounterCard(this.info, {super.key});

  final CounterInfo info;

  @override
  Widget build(BuildContext context) {
    final values = [
      ('${info.elapsed.years}', 'Anos'),
      ('${info.elapsed.months}', 'Meses'),
      ('${info.elapsed.days}', 'Dias'),
    ];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: info.colors),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .26)),
        boxShadow: [BoxShadow(color: info.colors.last.withValues(alpha: .24), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(info.icon, style: const TextStyle(fontSize: 29)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  info.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_formatDate(info.date), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 4),
          Text(info.message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const Spacer(),
          Row(
            children: values
                .map(
                  (value) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .95), borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          Text(value.$1, style: const TextStyle(color: _primary, fontWeight: FontWeight.w900, fontSize: 22)),
                          Text(value.$2, style: const TextStyle(color: _muted, fontWeight: FontWeight.w600, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              border: Border.all(color: Colors.white.withValues(alpha: .25)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${info.elapsed.isFuture ? 'Faltam' : 'Já se passaram'} ${info.elapsed.totalDays} dias',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = ['janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'];
  return '${date.day.toString().padLeft(2, '0')} de ${months[date.month - 1]} de ${date.year}';
}

String _initialFor(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.substring(0, 1).toUpperCase();
}

class StoryPage extends StatelessWidget {
  const StoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      ('Como Nos Conhecemos', 'Nossa historia comecou de uma forma moderna e especial, atraves de um aplicativo de relacionamento da nossa igreja. O que comecou como uma simples conversa logo se transformou em algo muito especial.'),
      ('Nosso Relacionamento', 'Oficialmente comecamos nosso namoro em 12 de outubro de 2024. Desde entao, temos compartilhado momentos incriveis juntos, construindo uma relacao baseada em amor, respeito e valores em comum.'),
      ('Nossa Conexao', 'Nossa fe e valores compartilhados tem sido a base do nosso relacionamento. Unidos pela igreja e por nossos principios, construimos uma conexao verdadeira e especial.'),
    ];
    return LoveBackground(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SectionTitle('Nossa Historia'),
          const SizedBox(height: 24),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                children: sections.map((section) => LoveTextCard(title: section.$1, body: section.$2)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final messages = [
      ('Meu Amor', 'Cada dia ao seu lado e uma nova aventura cheia de amor e felicidade...', '10 de Novembro, 2024'),
      ('Para Sempre', 'Voce e o sonho que eu nao sabia que tinha ate te encontrar...', '11 de Fevereiro, 2024'),
    ];
    return LoveBackground(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SectionTitle('Mensagens do Coracao'),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 3
                  : constraints.maxWidth >= 620
                      ? 2
                      : 1;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: columns,
                childAspectRatio: 1.15,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
                children: messages
                    .map(
                      (message) => LoveTextCard(
                        title: message.$1,
                        body: message.$2,
                        footer: message.$3,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class LoveTextCard extends StatelessWidget {
  const LoveTextCard({super.key, required this.title, required this.body, this.footer});

  final String title;
  final String body;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: _primary, fontWeight: FontWeight.w800, fontSize: 22)),
            const SizedBox(height: 12),
            Text(body, style: const TextStyle(color: _muted, fontSize: 16, height: 1.45)),
            if (footer != null) ...[
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: Text(footer!, style: const TextStyle(color: _primary, fontStyle: FontStyle.italic)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ResourcePage extends StatefulWidget {
  const ResourcePage({super.key, required this.title, required this.resource, required this.repository});

  final String title;
  final String resource;
  final FamilyRepository repository;

  @override
  State<ResourcePage> createState() => _ResourcePageState();
}

class _ResourcePageState extends State<ResourcePage> {
  late Future<List<FamilyItem>> future = widget.repository.list(widget.resource);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LoveBackground(
        child: FutureBuilder<List<FamilyItem>>(
          future: future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final items = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async => setState(() => future = widget.repository.list(widget.resource)),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  SectionTitle(widget.title),
                  const SizedBox(height: 24),
                  if (items.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Text('${widget.title} ainda esta vazio.', textAlign: TextAlign.center, style: const TextStyle(color: _muted)),
                      ),
                    )
                  else
                    ...items.map(
                      (item) => Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                          leading: CircleAvatar(
                            backgroundColor: _primary.withValues(alpha: .12),
                            foregroundColor: _primary,
                            child: Icon(_iconFor(widget.resource)),
                          ),
                          title: Text(item.title, style: const TextStyle(color: _primary, fontWeight: FontWeight.w800)),
                          subtitle: item.subtitle.isEmpty
                              ? null
                              : Text(item.subtitle, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, height: 1.35)),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        onPressed: () => _openCreate(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _iconFor(String resource) {
    return switch (resource) {
      'musicas' => Icons.music_note,
      'fotos' => Icons.photo,
      'cartas' => Icons.card_giftcard,
      _ => Icons.favorite,
    };
  }

  void _openCreate(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => ResourceDialog(
        title: widget.title,
        resource: widget.resource,
        onSave: (data) async {
          await widget.repository.create(widget.resource, data);
          setState(() => future = widget.repository.list(widget.resource));
        },
      ),
    );
  }
}

class ResourceDialog extends StatefulWidget {
  const ResourceDialog({super.key, required this.title, required this.resource, required this.onSave});

  final String title;
  final String resource;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  @override
  State<ResourceDialog> createState() => _ResourceDialogState();
}

class _ResourceDialogState extends State<ResourceDialog> {
  final title = TextEditingController();
  final subtitle = TextEditingController();
  final extra = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Novo item em ${widget.title}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Titulo ou URL')),
            TextField(controller: subtitle, decoration: const InputDecoration(labelText: 'Texto / artista')),
            TextField(controller: extra, decoration: const InputDecoration(labelText: 'Extra')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _save, child: const Text('Salvar')),
      ],
    );
  }

  Future<void> _save() async {
    final data = switch (widget.resource) {
      'musicas' => {
          'titulo': title.text,
          'artista': subtitle.text,
          'linkSpotify': extra.text,
          'momento': 'Especial',
        },
      'cartas' => {'titulo': title.text, 'conteudo': subtitle.text},
      'fotos' => {'url': title.text, 'texto': subtitle.text, 'tipo': extra.text == 'video' ? 'video' : 'imagem'},
      _ => <String, dynamic>{},
    };
    await widget.onSave(data);
    if (mounted) Navigator.pop(context);
  }
}

class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LoveBackground(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SectionTitle('Jogos do Amor'),
          SizedBox(height: 24),
          LoveTextCard(title: 'Quiz do Amor', body: 'Perguntas simples para brincar e relembrar detalhes da nossa historia.'),
          LoveTextCard(title: 'Caca Palavras', body: 'Palavras especiais em um jogo rapido para dias leves.'),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final user = auth.user;
    return LoveBackground(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: user == null
                  ? const Text('Entre para ver seu perfil.', textAlign: TextAlign.center, style: TextStyle(color: _muted))
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: _primary.withValues(alpha: .16),
                          foregroundColor: _primary,
                          child: Text(_initialFor(user.name ?? user.email), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(height: 16),
                        Text(user.name ?? 'Sem nome', textAlign: TextAlign.center, style: const TextStyle(color: _primary, fontWeight: FontWeight.w800, fontSize: 22)),
                        const SizedBox(height: 6),
                        Text(user.email, textAlign: TextAlign.center, style: const TextStyle(color: _muted)),
                        Text('Role: ${user.role}', textAlign: TextAlign.center, style: const TextStyle(color: _muted)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminPage extends StatelessWidget {
  const AdminPage({super.key, required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return LoveBackground(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SectionTitle('Administracao'),
          SizedBox(height: 24),
          LoveTextCard(title: 'Usuarios', body: 'Gerenciamento via eventos users.* com permissao de admin.'),
          LoveTextCard(title: 'Notificacoes', body: 'Envio, agendamento e historico via WebSocket.'),
        ],
      ),
    );
  }
}

class AuthSheet extends StatefulWidget {
  const AuthSheet({super.key, required this.auth});

  final AuthController auth;

  @override
  State<AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<AuthSheet> {
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  bool register = false;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(register ? 'Criar conta' : 'Entrar', style: const TextStyle(color: _primary, fontWeight: FontWeight.w800, fontSize: 24)),
          const SizedBox(height: 12),
          if (register) TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome')),
          TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: password, decoration: const InputDecoration(labelText: 'Senha'), obscureText: true),
          const SizedBox(height: 16),
          FilledButton(onPressed: loading ? null : _submit, child: Text(register ? 'Cadastrar' : 'Entrar')),
          TextButton(onPressed: () => setState(() => register = !register), child: Text(register ? 'Ja tenho conta' : 'Criar conta')),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => loading = true);
    try {
      if (register) {
        await widget.auth.register(email.text, password.text, name.text);
      } else {
        await widget.auth.signIn(email.text, password.text);
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}
