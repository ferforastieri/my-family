import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_sheet.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.auth,
    required this.child,
    required this.currentLocation,
  });

  final AuthController auth;
  final Widget child;
  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    final items = [
      const _HeaderItem('Nosso Início', '/', Icons.home_outlined, Icons.home),
      const _HeaderItem('Nossa Jornada', '/nossa-historia', Icons.menu_book_outlined, Icons.menu_book),
      const _HeaderItem('Quiz do Amor', '/quiz-do-amor', Icons.favorite_outline, Icons.favorite),
      const _HeaderItem('Nossa Playlist', '/playlist', Icons.music_note_outlined, Icons.music_note),
      const _HeaderItem('Palavras do Coração', '/mensagens', Icons.mail_outline, Icons.mail),
      const _HeaderItem('Carta de Amor', '/carta-de-amor', Icons.card_giftcard_outlined, Icons.card_giftcard),
      const _HeaderItem('Flor para Minha Esposa', '/flor-para-esposa', Icons.local_florist_outlined, Icons.local_florist),
      const _HeaderItem('Jogos do Amor', '/jogos', Icons.sports_esports_outlined, Icons.sports_esports),
      if (auth.user != null) const _HeaderItem('Memórias em Fotos', '/galeria', Icons.photo_outlined, Icons.photo),
      const _HeaderItem('Perfil', '/perfil', Icons.person_outline, Icons.person),
      if (auth.user?.role == 'admin') const _HeaderItem('Administração', '/admin', Icons.admin_panel_settings_outlined, Icons.admin_panel_settings),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 860;
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 64,
            titleSpacing: wide ? 28 : 16,
            title: InkWell(
              onTap: () => context.go('/'),
              child: const Text(
                '💕 Nossa Família',
                style: TextStyle(color: primary, fontWeight: FontWeight.w900, fontSize: 21),
              ),
            ),
            actions: [
              if (wide) _TopNavigation(items: items, currentLocation: currentLocation),
              IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_outlined), tooltip: 'Notificações'),
              if (wide) ...[
                if (auth.user == null)
                  TextButton.icon(
                    onPressed: () => _openLogin(context),
                    icon: const Icon(Icons.account_circle_outlined, size: 20),
                    label: const Text('Entrar'),
                  )
                else
                  IconButton(onPressed: auth.signOut, icon: const Icon(Icons.logout), tooltip: 'Sair'),
                const SizedBox(width: 14),
              ] else
                _HeaderMenu(items: items, auth: auth, currentLocation: currentLocation, onLogin: () => _openLogin(context)),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: border),
            ),
          ),
          body: child,
        );
      },
    );
  }

  void _openLogin(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AuthSheet(auth: auth),
    );
  }
}

class _HeaderItem {
  const _HeaderItem(this.label, this.path, this.icon, this.selectedIcon);

  final String label;
  final String path;
  final IconData icon;
  final IconData selectedIcon;
}

class _TopNavigation extends StatelessWidget {
  const _TopNavigation({required this.items, required this.currentLocation});

  final List<_HeaderItem> items;
  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: Colors.white,
      alignment: Alignment.center,
      constraints: const BoxConstraints(maxWidth: 980),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: TextButton.icon(
                  onPressed: () => context.go(item.path),
                  icon: Icon(_isSelected(item.path, currentLocation) ? item.selectedIcon : item.icon, size: 19),
                  label: Text(item.label),
                  style: TextButton.styleFrom(
                    foregroundColor: _isSelected(item.path, currentLocation) ? primary : foreground,
                    backgroundColor: _isSelected(item.path, currentLocation) ? primary.withValues(alpha: .08) : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderMenu extends StatelessWidget {
  const _HeaderMenu({
    required this.items,
    required this.auth,
    required this.currentLocation,
    required this.onLogin,
  });

  final List<_HeaderItem> items;
  final AuthController auth;
  final String currentLocation;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu),
      tooltip: 'Menu',
      onSelected: (value) {
        if (value == '_login') return onLogin();
        if (value == '_logout') {
          auth.signOut();
          return;
        }
        context.go(value);
      },
      itemBuilder: (context) => [
        for (final item in items)
          PopupMenuItem(
            value: item.path,
            child: Row(
              children: [
                Icon(_isSelected(item.path, currentLocation) ? item.selectedIcon : item.icon, color: primary),
                const SizedBox(width: 12),
                Expanded(child: Text(item.label)),
              ],
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: auth.user == null ? '_login' : '_logout',
          child: Row(
            children: [
              Icon(auth.user == null ? Icons.account_circle_outlined : Icons.logout, color: primary),
              const SizedBox(width: 12),
              Text(auth.user == null ? 'Entrar' : 'Sair'),
            ],
          ),
        ),
      ],
    );
  }
}

bool _isSelected(String itemPath, String currentLocation) {
  if (itemPath == '/') return currentLocation == '/';
  return currentLocation == itemPath || currentLocation.startsWith('$itemPath/');
}
