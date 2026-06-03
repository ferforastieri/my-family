import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/chat/chat_controller.dart';
import '../../../core/notifications/notifications_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../auth/presentation/auth_sheet.dart';
import '../../notifications/presentation/notifications_sheet.dart';
import '../../profile/presentation/edit_profile_sheet.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.auth,
    required this.notifications,
    required this.chat,
    required this.theme,
    required this.child,
    required this.currentLocation,
    required this.toast,
  });

  final AuthController auth;
  final NotificationsController notifications;
  final ChatController chat;
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
          appBar: wide ? _buildDesktopAppBar(context, items) : null,
          body: child,
          bottomNavigationBar: wide
              ? null
              : _MobileBottomNavigation(
                  auth: auth,
                  currentLocation: currentLocation,
                  onLogin: () => _openLogin(context),
                ),
        );
      },
    );
  }

  PreferredSizeWidget _buildDesktopAppBar(
      BuildContext context, List<_HeaderItem> items) {
    return AppBar(
      toolbarHeight: 92,
      titleSpacing: 0,
      leadingWidth: 128,
      leading: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 22),
          child: _Logo(onTap: () => context.go('/')),
        ),
      ),
      title: Center(
        child: _TopNavigation(
          items: items,
          currentLocation: currentLocation,
        ),
      ),
      actions: [
        IconButton(
            onPressed: () => _openNotificationsSheet(context),
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notificações'),
        IconButton(
            onPressed: () => _openThemeSheet(context),
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Cor e tema'),
        _ProfileAction(
          auth: auth,
          wide: true,
          onLogin: () => _openLogin(context),
          onEditProfile: () => _openEditProfileSheet(context),
          onAdmin: () => context.go('/admin'),
          onSignOut: () => _signOut(context),
        ),
        const SizedBox(width: 14),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1),
      ),
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
      const _HeaderItem('Nossa Playlist', '/playlist',
          Icons.music_note_outlined, Icons.music_note),
      const _HeaderItem(
          'Palavras do Coração', '/mensagens', Icons.mail_outline, Icons.mail),
      const _HeaderItem('Carta de Amor', '/carta-de-amor',
          Icons.card_giftcard_outlined, Icons.card_giftcard),
      const _HeaderItem('Jogos do Amor', '/jogos',
          Icons.sports_esports_outlined, Icons.sports_esports),
    ];
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

  void _openEditProfileSheet(BuildContext context) {
    showAppSheet<void>(
      context: context,
      builder: (_) => EditProfileSheet(auth: auth, toast: toast),
    );
  }

  void _openNotificationsSheet(BuildContext context) {
    showAppSheet<void>(
      context: context,
      builder: (_) => NotificationsSheet(notifications: notifications),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.auth,
    required this.wide,
    required this.onLogin,
    required this.onEditProfile,
    required this.onAdmin,
    required this.onSignOut,
  });

  final AuthController auth;
  final bool wide;
  final VoidCallback onLogin;
  final VoidCallback onEditProfile;
  final VoidCallback onAdmin;
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
    return AppDropdown<_ProfileMenuAction>(
      tooltip: 'Perfil',
      onSelected: (value) {
        switch (value) {
          case _ProfileMenuAction.editProfile:
            onEditProfile();
          case _ProfileMenuAction.admin:
            onAdmin();
          case _ProfileMenuAction.signOut:
            onSignOut();
        }
      },
      actions: [
        const AppDropdownAction(
            value: _ProfileMenuAction.editProfile,
            label: 'Editar perfil',
            icon: Icons.person_outline),
        if (user.role == 'admin')
          const AppDropdownAction(
              value: _ProfileMenuAction.admin,
              label: 'Administração',
              icon: Icons.admin_panel_settings_outlined),
        const AppDropdownAction(
            value: _ProfileMenuAction.signOut,
            label: 'Sair',
            icon: Icons.logout,
            destructive: true),
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

enum _ProfileMenuAction { editProfile, admin, signOut }

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Image.asset(
          'assets/brand/family-logo.png',
          width: 78,
          height: 78,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _MobileBottomNavigation extends StatelessWidget {
  const _MobileBottomNavigation({
    required this.auth,
    required this.currentLocation,
    required this.onLogin,
  });

  final AuthController auth;
  final String currentLocation;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.card,
          border: Border(top: BorderSide(color: palette.border)),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withValues(alpha: .12),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SizedBox(
          height: 76,
          child: Row(
            children: [
              _MobileNavButton(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Início',
                selected: _isSelected('/atalhos/inicio', currentLocation) ||
                    currentLocation == '/' ||
                    currentLocation == '/nossa-historia' ||
                    currentLocation == '/mensagens',
                onTap: () => context.go('/atalhos/inicio'),
              ),
              _MobileNavButton(
                icon: Icons.photo_library_outlined,
                selectedIcon: Icons.photo_library,
                label: 'Memórias',
                selected: _isSelected('/atalhos/memorias', currentLocation) ||
                    currentLocation == '/galeria' ||
                    currentLocation == '/playlist' ||
                    currentLocation == '/carta-de-amor',
                onTap: () => context.go('/atalhos/memorias'),
              ),
              Expanded(
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, -16),
                    child: InkWell(
                      onTap: () => context.go('/chat'),
                      customBorder: const CircleBorder(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 72,
                        height: 72,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: palette.card,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isSelected('/chat', currentLocation)
                                ? palette.primary
                                : palette.border,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: palette.primary.withValues(alpha: .20),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/brand/family-logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _MobileNavButton(
                icon: Icons.apps_outlined,
                selectedIcon: Icons.apps,
                label: 'Mais',
                selected: _isSelected('/atalhos/mais', currentLocation) ||
                    currentLocation == '/jogos',
                onTap: () => context.go('/atalhos/mais'),
              ),
              _MobileNavButton(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: 'Perfil',
                selected: _isSelected('/perfil', currentLocation) ||
                    _isSelected('/admin', currentLocation),
                onTap: () {
                  if (auth.user == null) {
                    onLogin();
                  } else {
                    context.go('/perfil');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileNavButton extends StatelessWidget {
  const _MobileNavButton({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final color = selected ? palette.primary : palette.muted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? selectedIcon : icon, color: color, size: 23),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MobileOptionsPage extends StatelessWidget {
  const MobileOptionsPage({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<MobileOptionItem> items;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.bgStart, palette.bgEnd],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 28, 18, 112),
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.primary,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 22),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: palette.card,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => context.go(item.path),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      border: Border.all(color: palette.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              palette.primary.withValues(alpha: .14),
                          foregroundColor: palette.primary,
                          child: Icon(item.icon),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.label,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Text(item.description,
                                  style: TextStyle(color: palette.muted)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MobileOptionItem {
  const MobileOptionItem({
    required this.label,
    required this.description,
    required this.path,
    required this.icon,
  });

  final String label;
  final String description;
  final String path;
  final IconData icon;
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
