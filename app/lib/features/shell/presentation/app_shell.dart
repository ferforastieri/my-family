import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../auth/presentation/auth_sheet.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.auth,
    required this.theme,
    required this.child,
    required this.currentLocation,
    required this.toast,
  });

  final AuthController auth;
  final ThemeController theme;
  final Widget child;
  final String currentLocation;
  final ToastController toast;

  @override
  Widget build(BuildContext context) {
    final items = _navigationItems(isAuthenticated: auth.user != null);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 860;
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 64,
            titleSpacing: 0,
            leadingWidth: wide ? 220 : null,
            leading: wide
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 22),
                      child: _Logo(onTap: () => context.go('/')),
                    ),
                  )
                : null,
            title: wide
                ? Center(
                    child: _TopNavigation(
                      items: items,
                      currentLocation: currentLocation,
                    ),
                  )
                : _Logo(onTap: () => context.go('/')),
            actions: [
              IconButton(
                  onPressed: () => toast.info('Notificações em breve.'),
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Notificações'),
              IconButton(
                  onPressed: () => _openThemeSheet(context),
                  icon: const Icon(Icons.palette_outlined),
                  tooltip: 'Cor e tema'),
              if (wide) ...[
                _ProfileAction(
                  auth: auth,
                  wide: true,
                  onLogin: () => _openLogin(context),
                  onSettings: () => _openThemeSheet(context),
                  onEditProfile: () => context.go('/perfil'),
                  onSignOut: () => _signOut(context),
                ),
                const SizedBox(width: 14),
              ] else
                _ProfileAction(
                  auth: auth,
                  wide: false,
                  onLogin: () => _openLogin(context),
                  onSettings: () => _openThemeSheet(context),
                  onEditProfile: () => context.go('/perfil'),
                  onSignOut: () => _signOut(context),
                ),
              if (!wide)
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

  List<_HeaderItem> _navigationItems({required bool isAuthenticated}) {
    return [
      const _HeaderItem('Nosso Início', '/', Icons.home_outlined, Icons.home),
      const _HeaderItem('Nossa Jornada', '/nossa-historia',
          Icons.menu_book_outlined, Icons.menu_book),
      if (isAuthenticated)
        const _HeaderItem(
            'Memórias em Fotos', '/galeria', Icons.photo_outlined, Icons.photo),
      const _HeaderItem('Quiz do Amor', '/quiz-do-amor', Icons.favorite_outline,
          Icons.favorite),
      const _HeaderItem('Nossa Playlist', '/playlist',
          Icons.music_note_outlined, Icons.music_note),
      const _HeaderItem(
          'Palavras do Coração', '/mensagens', Icons.mail_outline, Icons.mail),
      const _HeaderItem('Carta de Amor', '/carta-de-amor',
          Icons.card_giftcard_outlined, Icons.card_giftcard),
      const _HeaderItem('Flor para Minha Esposa', '/flor-para-esposa',
          Icons.local_florist_outlined, Icons.local_florist),
      const _HeaderItem('Jogos do Amor', '/jogos',
          Icons.sports_esports_outlined, Icons.sports_esports),
      const _HeaderItem('Caça Palavras', '/caca-palavras',
          Icons.grid_on_outlined, Icons.grid_on),
      if (isAuthenticated)
        const _HeaderItem('Administração', '/admin',
            Icons.admin_panel_settings_outlined, Icons.admin_panel_settings),
    ];
  }

  void _openMenuSheet(BuildContext context, List<_HeaderItem> items) {
    showAppSheet<void>(
      context: context,
      builder: (_) => _HeaderMenuSheet(
        items: items,
        currentLocation: currentLocation,
      ),
    );
  }

  void _openLogin(BuildContext context) {
    showAppSheet<void>(
      context: context,
      builder: (context) => AuthSheet(auth: auth, toast: toast),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await auth.signOut();
    toast.success('Você saiu da conta.');
    if (context.mounted) context.go('/');
  }

  void _openThemeSheet(BuildContext context) {
    showAppSheet<void>(
      context: context,
      builder: (_) => _ThemeSheet(theme: theme, toast: toast),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.auth,
    required this.wide,
    required this.onLogin,
    required this.onSettings,
    required this.onEditProfile,
    required this.onSignOut,
  });

  final AuthController auth;
  final bool wide;
  final VoidCallback onLogin;
  final VoidCallback onSettings;
  final VoidCallback onEditProfile;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final user = auth.user;
    if (user == null) {
      if (!wide) {
        return IconButton(
          onPressed: onLogin,
          icon: const Icon(Icons.account_circle_outlined),
          tooltip: 'Entrar',
        );
      }
      return TextButton.icon(
        onPressed: onLogin,
        icon: const Icon(Icons.account_circle_outlined, size: 20),
        label: const Text('Entrar'),
      );
    }

    final palette = Theme.of(context).extension<AppPalette>()!;
    return PopupMenuButton<_ProfileMenuAction>(
      tooltip: 'Perfil',
      offset: const Offset(0, 12),
      onSelected: (value) {
        switch (value) {
          case _ProfileMenuAction.settings:
            onSettings();
          case _ProfileMenuAction.editProfile:
            onEditProfile();
          case _ProfileMenuAction.signOut:
            onSignOut();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _ProfileMenuAction.settings,
          child: ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text('Configurações'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: _ProfileMenuAction.editProfile,
          child: ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Editar perfil'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _ProfileMenuAction.signOut,
          child: ListTile(
            leading: Icon(Icons.logout),
            title: Text('Sair'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: wide ? 8 : 4),
        child: CircleAvatar(
          radius: wide ? 18 : 17,
          backgroundColor: palette.primary.withValues(alpha: .14),
          foregroundColor: palette.primary,
          child: Text(
            _initialFor(user.name ?? user.email),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
        ),
      ),
    );
  }
}

enum _ProfileMenuAction { settings, editProfile, signOut }

class _ThemeSheet extends StatelessWidget {
  const _ThemeSheet({required this.theme, required this.toast});

  final ThemeController theme;
  final ToastController toast;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cor e tema',
            style: TextStyle(
                color: palette.primary,
                fontSize: 22,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        const Text('Cor', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Row(
          children: [
            _ColorChoice(
                theme: theme,
                toast: toast,
                value: ThemeColorChoice.rosa,
                color: const Color(0xffff69b4),
                label: 'Rosa'),
            _ColorChoice(
                theme: theme,
                toast: toast,
                value: ThemeColorChoice.azul,
                color: const Color(0xff3b82f6),
                label: 'Azul'),
            _ColorChoice(
                theme: theme,
                toast: toast,
                value: ThemeColorChoice.vermelho,
                color: const Color(0xffef4444),
                label: 'Vermelho'),
          ],
        ),
        const SizedBox(height: 18),
        const Text('Modo', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined),
                label: Text('Claro')),
            ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined),
                label: Text('Escuro')),
          ],
          selected: {theme.mode},
          onSelectionChanged: (value) {
            theme.setMode(value.first);
            toast.success(value.first == ThemeMode.dark
                ? 'Modo escuro ativado.'
                : 'Modo claro ativado.');
          },
        ),
      ],
    );
  }
}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice(
      {required this.theme,
      required this.toast,
      required this.value,
      required this.color,
      required this.label});

  final ThemeController theme;
  final ToastController toast;
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
          onTap: () {
            theme.setColor(value);
            toast.success('Cor $label aplicada.');
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                  color: selected
                      ? Theme.of(context).extension<AppPalette>()!.foreground
                      : Colors.transparent,
                  width: 3),
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
          style: TextStyle(
              color: palette.primary,
              fontWeight: FontWeight.w900,
              fontSize: 21),
        ),
      ),
    );
  }
}

class _HeaderMenuSheet extends StatelessWidget {
  const _HeaderMenuSheet({
    required this.items,
    required this.currentLocation,
  });

  final List<_HeaderItem> items;
  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Menu',
                  style: TextStyle(
                      color: palette.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final item in items)
                    ListTile(
                      leading: Icon(
                          _isSelected(item.path, currentLocation)
                              ? item.selectedIcon
                              : item.icon,
                          color: palette.primary),
                      title: Text(item.label),
                      selected: _isSelected(item.path, currentLocation),
                      selectedTileColor: palette.primary.withValues(alpha: .08),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      onTap: () {
                        Navigator.pop(context);
                        context.go(item.path);
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
      height: 48,
      color: palette.card,
      alignment: Alignment.center,
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
                  icon: Icon(
                      _isSelected(item.path, currentLocation)
                          ? item.selectedIcon
                          : item.icon,
                      size: 19),
                  label: Text(item.label),
                  style: TextButton.styleFrom(
                    foregroundColor: _isSelected(item.path, currentLocation)
                        ? palette.primary
                        : palette.foreground,
                    backgroundColor: _isSelected(item.path, currentLocation)
                        ? palette.primary.withValues(alpha: .08)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12),
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
  return currentLocation == itemPath ||
      currentLocation.startsWith('$itemPath/');
}

String _initialFor(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.substring(0, 1).toUpperCase();
}
