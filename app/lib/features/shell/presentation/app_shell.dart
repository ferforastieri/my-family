import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/family_repository.dart';
import '../../admin/presentation/admin_page.dart';
import '../../auth/presentation/auth_sheet.dart';
import '../../games/presentation/games_page.dart';
import '../../home/presentation/home_page.dart';
import '../../messages/presentation/messages_page.dart';
import '../../profile/presentation/profile_page.dart';
import '../../resources/presentation/resource_page.dart';
import '../../story/presentation/story_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.auth, required this.repository});

  final AuthController auth;
  final FamilyRepository repository;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onNavigate: (page) => setState(() => index = page)),
      const StoryPage(),
      const MessagesPage(),
      ResourcePage(title: 'Carta de Amor', resource: 'cartas', repository: widget.repository),
      ResourcePage(title: 'Nossa Playlist', resource: 'musicas', repository: widget.repository),
      ResourcePage(title: 'Memórias em Fotos', resource: 'fotos', repository: widget.repository),
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
              style: TextStyle(color: primary, fontWeight: FontWeight.w900, fontSize: 21),
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
                  const Divider(height: 1, color: border),
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
                  indicatorColor: primary.withValues(alpha: .14),
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
                    foregroundColor: i == selected ? primary : foreground,
                    backgroundColor: i == selected ? primary.withValues(alpha: .08) : Colors.transparent,
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

