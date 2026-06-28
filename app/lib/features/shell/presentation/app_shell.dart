import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/chat/chat_controller.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/notifications/notifications_controller.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_fixed_header_scroll_view.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/love_action_card.dart';
import '../../auth/presentation/auth_sheet.dart';
import '../../notifications/presentation/notifications_sheet.dart';

enum AppShellSection { family, panel, platform }

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.auth,
    required this.notifications,
    required this.chat,
    required this.theme,
    required this.locale,
    required this.child,
    required this.currentLocation,
    required this.toast,
    this.section = AppShellSection.family,
  });

  final AuthController auth;
  final NotificationsController notifications;
  final ChatController chat;
  final ThemeController theme;
  final LocaleController locale;
  final Widget child;
  final String currentLocation;
  final ToastController toast;
  final AppShellSection section;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([notifications, chat]),
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 860;
          return Scaffold(
            appBar: wide ? _buildDesktopAppBar(context) : null,
            body: AppHeaderActionsScope(
              onNotifications: () => _openNotificationsSheet(context),
              onTheme: () => _openThemeSheet(context),
              onLanguage: () => _openLanguageSheet(context),
              notificationCount: notifications.badgeCount,
              child: child,
            ),
            bottomNavigationBar: wide
                ? null
                : _MobileBottomNavigation(
                    auth: auth,
                    section: section,
                    chatUnreadCount: chat.unreadCount,
                    currentLocation: currentLocation,
                    onLogin: () => _openLogin(context),
                  ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildDesktopAppBar(BuildContext context) {
    return AppBar(
      toolbarHeight: 92,
      titleSpacing: 0,
      leadingWidth: 0,
      leading: const SizedBox.shrink(),
      title: Center(
        child: _DesktopMainNavigation(
          auth: auth,
          section: section,
          chatUnreadCount: chat.unreadCount,
          currentLocation: currentLocation,
          onLogin: () => _openLogin(context),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _openLanguageSheet(context),
          icon: const Icon(Icons.translate_outlined),
          tooltip: context.tr('Idioma'),
        ),
        IconButton(
          onPressed: () => _openNotificationsSheet(context),
          icon: _BadgeIcon(
            count: notifications.badgeCount,
            child: const Icon(Icons.notifications_outlined),
          ),
          tooltip: context.tr('Notificações'),
        ),
        IconButton(
          onPressed: () => _openThemeSheet(context),
          icon: const Icon(Icons.palette_outlined),
          tooltip: context.tr('Cor e tema'),
        ),
        const SizedBox(width: 14),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1),
      ),
    );
  }

  void _openLogin(BuildContext context) {
    showAppSheet<void>(
      context: context,
      builder: (context) => AuthSheet(auth: auth, toast: toast),
    );
  }

  void _openThemeSheet(BuildContext context) {
    showAppSheet<void>(
      context: context,
      builder: (_) => _ThemeSheet(theme: theme, toast: toast),
    );
  }

  void _openLanguageSheet(BuildContext context) {
    showAppSheet<void>(
      context: context,
      builder: (_) => _LanguageSheet(locale: locale),
    );
  }

  void _openNotificationsSheet(BuildContext context) {
    unawaited(notifications.markAllRead());
    showAppSheet<void>(
      context: context,
      builder: (_) => NotificationsSheet(notifications: notifications),
    );
  }
}

class _DesktopMainNavigation extends StatelessWidget {
  const _DesktopMainNavigation({
    required this.auth,
    required this.section,
    required this.chatUnreadCount,
    required this.currentLocation,
    required this.onLogin,
  });

  final AuthController auth;
  final AppShellSection section;
  final int chatUnreadCount;
  final String currentLocation;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final items = _navigationItems(section, auth, currentLocation, onLogin);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 960),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final item in items)
            if (item.logo)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InkWell(
                  onTap: () => _openNavItem(context, item),
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
                        color: item.selected ? palette.primary : palette.border,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: palette.primary.withValues(alpha: .16),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _BadgeIcon(
                      count: section == AppShellSection.family
                          ? chatUnreadCount
                          : 0,
                      child: Image.asset(
                        'assets/brand/family-logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              )
            else
              _DesktopNavPill(
                icon: item.icon,
                selectedIcon: item.selectedIcon,
                label: item.label,
                selected: item.selected,
                onTap: () => _openNavItem(context, item),
              ),
        ],
      ),
    );
  }
}

class _NavigationItem {
  const _NavigationItem({
    required this.label,
    required this.path,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    this.logo = false,
    this.enabled = true,
    this.onDisabled,
  });

  final String label;
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final bool logo;
  final bool enabled;
  final VoidCallback? onDisabled;
}

List<_NavigationItem> _navigationItems(
  AppShellSection section,
  AuthController auth,
  String currentLocation,
  VoidCallback onLogin,
) {
  return switch (section) {
    AppShellSection.family => _familyNavigation(auth, currentLocation, onLogin),
    AppShellSection.panel => _panelNavigation(currentLocation),
    AppShellSection.platform => _platformNavigation(currentLocation),
  };
}

List<_NavigationItem> _familyNavigation(
  AuthController auth,
  String currentLocation,
  VoidCallback onLogin,
) {
  final user = auth.user;
  final hasMemories = user?.canAccess('memorias') == true ||
      user?.canAccess('playlist') == true ||
      user?.canAccess('cartas') == true ||
      user?.canAccess('nossaHistoria') == true;
  final hasMore = user?.canAccess('jogos') == true ||
      user?.canAccess('listas') == true ||
      user?.canAccess('notas') == true ||
      user?.canAccess('localizacao') == true;
  return [
    _NavigationItem(
      label: 'Início',
      path: '/home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      selected: currentLocation == '/home',
      enabled: user != null,
      onDisabled: onLogin,
    ),
    _NavigationItem(
      label: 'Memórias',
      path: '/atalhos/memorias',
      icon: Icons.photo_library_outlined,
      selectedIcon: Icons.photo_library,
      selected: hasMemories &&
          (_isSelected('/atalhos/memorias', currentLocation) ||
              currentLocation == '/galeria' ||
              currentLocation == '/playlist' ||
              currentLocation == '/carta-de-amor' ||
              currentLocation == '/nossa-historia'),
      enabled: user != null && hasMemories,
      onDisabled: onLogin,
    ),
    _NavigationItem(
      label: 'Chat',
      path: '/chat',
      icon: Icons.chat_bubble_outline,
      selectedIcon: Icons.chat_bubble,
      selected: _isSelected('/chat', currentLocation),
      logo: true,
      enabled: user != null && user.canAccess('chat'),
      onDisabled: onLogin,
    ),
    _NavigationItem(
      label: 'Mais',
      path: '/atalhos/mais',
      icon: Icons.apps_outlined,
      selectedIcon: Icons.apps,
      selected: hasMore &&
          (_isSelected('/atalhos/mais', currentLocation) ||
              currentLocation == '/jogos' ||
              currentLocation == '/listas' ||
              currentLocation == '/notas' ||
              currentLocation == '/localizacao'),
      enabled: user != null && hasMore,
      onDisabled: onLogin,
    ),
    _NavigationItem(
      label: 'Perfil',
      path: '/perfil',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      selected: _isSelected('/perfil', currentLocation),
      enabled: user != null,
      onDisabled: onLogin,
    ),
  ];
}

List<_NavigationItem> _panelNavigation(String currentLocation) {
  return [
    _NavigationItem(
      label: 'Painel',
      path: '/painel',
      icon: Icons.tune_outlined,
      selectedIcon: Icons.tune,
      selected: _isSelected('/painel', currentLocation),
    ),
    _NavigationItem(
      label: 'Assinatura',
      path: '/billing',
      icon: Icons.workspace_premium_outlined,
      selectedIcon: Icons.workspace_premium,
      selected: _isSelected('/billing', currentLocation) ||
          currentLocation.contains('/assinatura'),
    ),
    _NavigationItem(
      label: 'Site',
      path: '/home',
      icon: Icons.family_restroom_outlined,
      selectedIcon: Icons.family_restroom,
      selected: currentLocation == '/home',
      logo: true,
    ),
    _NavigationItem(
      label: 'Administrar',
      path: '/admin/familia',
      icon: Icons.admin_panel_settings_outlined,
      selectedIcon: Icons.admin_panel_settings,
      selected: _isSelected('/admin/familia', currentLocation),
    ),
    _NavigationItem(
      label: 'Perfil',
      path: '/painel/perfil',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      selected: _isSelected('/painel/perfil', currentLocation),
    ),
  ];
}

List<_NavigationItem> _platformNavigation(String currentLocation) {
  return [
    _NavigationItem(
      label: 'Plataforma',
      path: '/admin/plataforma',
      icon: Icons.shield_outlined,
      selectedIcon: Icons.shield,
      selected: _isSelected('/admin/plataforma', currentLocation),
    ),
  ];
}

void _openNavItem(BuildContext context, _NavigationItem item) {
  if (!item.enabled) {
    item.onDisabled?.call();
    return;
  }
  context.openAppRoute(item.path);
}

class _DesktopNavPill extends StatelessWidget {
  const _DesktopNavPill({
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
    final color = selected ? palette.primary : palette.foreground;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(selected ? selectedIcon : icon, size: 20),
        label: Text(context.tr(label)),
        style: TextButton.styleFrom(
          foregroundColor: color,
          backgroundColor:
              selected ? palette.primary.withValues(alpha: .08) : null,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _ThemeSheet extends StatelessWidget {
  const _ThemeSheet({required this.theme, required this.toast});

  final ThemeController theme;
  final ToastController toast;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            context.tr('Cor e tema'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.primary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            context.tr('Cor'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
          const SizedBox(height: 20),
          Text(
            context.tr('Modo'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Center(
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode_outlined),
                    label: Text(context.tr('Claro'))),
                ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode_outlined),
                    label: Text(context.tr('Escuro'))),
              ],
              selected: {theme.mode},
              onSelectionChanged: (value) {
                theme.setMode(value.first);
                toast.success(value.first == ThemeMode.dark
                    ? context.tr('Modo escuro ativado.')
                    : context.tr('Modo claro ativado.'));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({required this.locale});

  final LocaleController locale;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final selected = AppLocalizations.storageCode(locale.locale);
    return SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('Idioma'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.primary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          for (final option in AppLocalizations.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: () {
                  locale.setLocale(option.locale);
                  Navigator.of(context).pop();
                },
                title: Text(option.nativeLabel),
                subtitle: Text(option.productName),
                trailing:
                    selected == AppLocalizations.storageCode(option.locale)
                        ? Icon(Icons.check_circle, color: palette.primary)
                        : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: palette.border),
                ),
              ),
            ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Tooltip(
        message: context.tr(label),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            theme.setColor(value);
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

class _MobileBottomNavigation extends StatelessWidget {
  const _MobileBottomNavigation({
    required this.auth,
    required this.section,
    required this.chatUnreadCount,
    required this.currentLocation,
    required this.onLogin,
  });

  final AuthController auth;
  final AppShellSection section;
  final int chatUnreadCount;
  final String currentLocation;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final items = _navigationItems(section, auth, currentLocation, onLogin);
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
              for (final item in items)
                if (item.logo)
                  Expanded(
                    child: Center(
                      child: InkWell(
                        onTap: () => _openNavItem(context, item),
                        customBorder: const CircleBorder(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 58,
                          height: 58,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: palette.card,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: item.selected
                                  ? palette.primary
                                  : palette.border,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: palette.primary.withValues(alpha: .14),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _BadgeIcon(
                            count: section == AppShellSection.family
                                ? chatUnreadCount
                                : 0,
                            child: Image.asset(
                              'assets/brand/family-logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  _MobileNavButton(
                    icon: item.icon,
                    selectedIcon: item.selectedIcon,
                    label: item.label,
                    selected: item.selected,
                    onTap: () => _openNavItem(context, item),
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
                context.tr(label),
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
      child: AppFixedHeaderScrollView(
        header: AppPageHeader(
          title: title,
          subtitle: 'Escolha para onde seguir.',
          icon: Icons.favorite_outline,
        ),
        headerGap: 22,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LoveActionCard(
                title: item.label,
                description: item.description,
                icon: item.icon,
                onTap: () => context.openAppRoute(item.path),
                maxWidth: 1200,
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

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -7,
          top: -7,
          child: _BadgeLabel(count: count),
        ),
      ],
    );
  }
}

class _BadgeLabel extends StatelessWidget {
  const _BadgeLabel({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : count.toString();
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).extension<AppPalette>()!.primary,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

bool _isSelected(String itemPath, String currentLocation) {
  if (itemPath == '/home') return currentLocation == '/home';
  return currentLocation == itemPath ||
      currentLocation.startsWith('$itemPath/');
}
