import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../auth/presentation/auth_sheet.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.auth,
    required this.theme,
    required this.child,
    required this.currentLocation,
  });

  final AuthController auth;
  final ThemeController theme;
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
            titleSpacing: 0,
            leadingWidth: wide ? 260 : null,
            leading: wide
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 28),
                      child: _Logo(onTap: () => context.go('/')),
                    ),
                  )
                : null,
            title: wide
                ? Center(child: _TopNavigation(items: items, currentLocation: currentLocation))
                : _Logo(onTap: () => context.go('/')),
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_outlined), tooltip: 'Notificações'),
              IconButton(onPressed: () => _openThemeSheet(context), icon: const Icon(Icons.palette_outlined), tooltip: 'Cor e tema'),
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
                IconButton(
                  onPressed: () => _openMenuSheet(context, items),
                  icon: const Icon(Icons.menu),
                  tooltip: 'Menu',
                ),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1),
            ),
          ),
          body: child,
        );
      },
    );
  }

  void _openMenuSheet(BuildContext context, List<_HeaderItem> items) {
    showAppSheet<void>(
      context: context,
      builder: (sheetContext) => _HeaderMenuSheet(
        items: items,
        auth: auth,
        currentLocation: currentLocation,
        onLogin: () {
          Navigator.pop(sheetContext);
          _openLogin(context);
        },
      ),
    );
  }

  void _openLogin(BuildContext context) {
    showAppSheet<void>(
      context: context,
      builder: (context) => AuthSheet(auth: auth),
    );
  }

  void _openThemeSheet(BuildContext context) {
    showAppSheet<void>(
      context: context,
      builder: (_) => _ThemeSheet(theme: theme),
    );
  }
}

class _ThemeSheet extends StatelessWidget {
  const _ThemeSheet({required this.theme});

  final ThemeController theme;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cor e tema', style: TextStyle(color: palette.primary, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        const Text('Cor', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Row(
          children: [
            _ColorChoice(theme: theme, value: ThemeColorChoice.rosa, color: const Color(0xffff69b4), label: 'Rosa'),
            _ColorChoice(theme: theme, value: ThemeColorChoice.azul, color: const Color(0xff3b82f6), label: 'Azul'),
            _ColorChoice(theme: theme, value: ThemeColorChoice.vermelho, color: const Color(0xffef4444), label: 'Vermelho'),
          ],
        ),
        const SizedBox(height: 18),
        const Text('Modo', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Claro')),
            ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Escuro')),
          ],
          selected: {theme.mode},
          onSelectionChanged: (value) => theme.setMode(value.first),
        ),
      ],
    );
  }
}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({required this.theme, required this.value, required this.color, required this.label});

  final ThemeController theme;
  final ThemeColorChoice value;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final selected = theme.color == value;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Tooltip(
        message: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => theme.setColor(value),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: selected ? Theme.of(context).extension<AppPalette>()!.foreground : Colors.transparent, width: 3),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Text(
          '💕 Nossa Família',
          style: TextStyle(color: palette.primary, fontWeight: FontWeight.w900, fontSize: 21),
        ),
      ),
    );
  }
}

class _HeaderMenuSheet extends StatelessWidget {
  const _HeaderMenuSheet({
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
    final palette = Theme.of(context).extension<AppPalette>()!;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Menu', style: TextStyle(color: palette.primary, fontSize: 22, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final item in items)
                    ListTile(
                      leading: Icon(_isSelected(item.path, currentLocation) ? item.selectedIcon : item.icon, color: palette.primary),
                      title: Text(item.label),
                      selected: _isSelected(item.path, currentLocation),
                      selectedTileColor: palette.primary.withValues(alpha: .08),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      onTap: () {
                        Navigator.pop(context);
                        context.go(item.path);
                      },
                    ),
                  Divider(height: 20, color: palette.border),
                  ListTile(
                    leading: Icon(auth.user == null ? Icons.account_circle_outlined : Icons.logout, color: palette.primary),
                    title: Text(auth.user == null ? 'Entrar' : 'Sair'),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    onTap: () {
                      if (auth.user == null) {
                        onLogin();
                      } else {
                        Navigator.pop(context);
                        auth.signOut();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Container(
      height: 64,
      color: palette.card,
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
                    foregroundColor: _isSelected(item.path, currentLocation) ? palette.primary : palette.foreground,
                    backgroundColor: _isSelected(item.path, currentLocation) ? palette.primary.withValues(alpha: .08) : Colors.transparent,
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

bool _isSelected(String itemPath, String currentLocation) {
  if (itemPath == '/') return currentLocation == '/';
  return currentLocation == itemPath || currentLocation.startsWith('$itemPath/');
}
