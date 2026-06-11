import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/chat/chat_controller.dart';
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
              notificationCount: notifications.badgeCount,
              child: child,
            ),
            bottomNavigationBar: wide
                ? null
                : _MobileBottomNavigation(
                    auth: auth,
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
          chatUnreadCount: chat.unreadCount,
          currentLocation: currentLocation,
          onLogin: () => _openLogin(context),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _openNotificationsSheet(context),
          icon: _BadgeIcon(
            count: notifications.badgeCount,
            child: const Icon(Icons.notifications_outlined),
          ),
          tooltip: 'Notificações',
        ),
        IconButton(
          onPressed: () => _openThemeSheet(context),
          icon: const Icon(Icons.palette_outlined),
          tooltip: 'Cor e tema',
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
    required this.chatUnreadCount,
    required this.currentLocation,
    required this.onLogin,
  });

  final AuthController auth;
  final int chatUnreadCount;
  final String currentLocation;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final user = auth.user;
    final hasMemories = user?.canAccess('memorias') == true ||
        user?.canAccess('playlist') == true ||
        user?.canAccess('cartas') == true ||
        user?.canAccess('nossaHistoria') == true;
    final hasMore = user?.canAccess('jogos') == true ||
        user?.canAccess('listas') == true ||
        user?.canAccess('localizacao') == true;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _DesktopNavPill(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Início',
            selected: currentLocation == '/',
            onTap: () => context.openAppRoute('/'),
          ),
          _DesktopNavPill(
            icon: Icons.photo_library_outlined,
            selectedIcon: Icons.photo_library,
            label: 'Memórias',
            selected: hasMemories &&
                (_isSelected('/atalhos/memorias', currentLocation) ||
                    currentLocation == '/galeria' ||
                    currentLocation == '/playlist' ||
                    currentLocation == '/carta-de-amor' ||
                    currentLocation == '/nossa-historia'),
            onTap: () {
              if (user == null) {
                onLogin();
              } else if (hasMemories) {
                context.openAppRoute('/atalhos/memorias');
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              onTap: () {
                if (user == null) {
                  onLogin();
                } else if (user.canAccess('chat')) {
                  context.openAppRoute('/chat');
                }
              },
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
                      color: palette.primary.withValues(alpha: .16),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _BadgeIcon(
                  count: chatUnreadCount,
                  child: Image.asset(
                    'assets/brand/family-logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          _DesktopNavPill(
            icon: Icons.apps_outlined,
            selectedIcon: Icons.apps,
            label: 'Mais',
            selected: hasMore &&
                (_isSelected('/atalhos/mais', currentLocation) ||
                    currentLocation == '/jogos' ||
                    currentLocation == '/listas' ||
                    currentLocation == '/localizacao'),
            onTap: () {
              if (user == null) {
                onLogin();
              } else if (hasMore) {
                context.openAppRoute('/atalhos/mais');
              }
            },
          ),
          _DesktopNavPill(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Perfil',
            selected: _isSelected('/perfil', currentLocation) ||
                _isSelected('/admin', currentLocation),
            onTap: () {
              if (auth.user == null) {
                onLogin();
              } else {
                context.openAppRoute('/perfil');
              }
            },
          ),
        ],
      ),
    );
  }
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
        label: Text(label),
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
            'Cor e tema',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.primary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Cor',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700),
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
          const Text(
            'Modo',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Center(
            child: SegmentedButton<ThemeMode>(
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
        message: label,
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
    required this.chatUnreadCount,
    required this.currentLocation,
    required this.onLogin,
  });

  final AuthController auth;
  final int chatUnreadCount;
  final String currentLocation;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final user = auth.user;
    final hasMemories = user?.canAccess('memorias') == true ||
        user?.canAccess('playlist') == true ||
        user?.canAccess('cartas') == true ||
        user?.canAccess('nossaHistoria') == true;
    final hasMore = user?.canAccess('jogos') == true ||
        user?.canAccess('listas') == true ||
        user?.canAccess('localizacao') == true;
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
                selected: currentLocation == '/',
                onTap: () => context.openAppRoute('/'),
              ),
              _MobileNavButton(
                icon: Icons.photo_library_outlined,
                selectedIcon: Icons.photo_library,
                label: 'Memórias',
                selected: hasMemories &&
                    (_isSelected('/atalhos/memorias', currentLocation) ||
                        currentLocation == '/galeria' ||
                        currentLocation == '/playlist' ||
                        currentLocation == '/carta-de-amor' ||
                        currentLocation == '/nossa-historia'),
                onTap: () {
                  if (user == null) {
                    onLogin();
                  } else if (hasMemories) {
                    context.openAppRoute('/atalhos/memorias');
                  }
                },
              ),
              Expanded(
                child: Center(
                  child: InkWell(
                    onTap: () {
                      if (user == null) {
                        onLogin();
                      } else if (user.canAccess('chat')) {
                        context.openAppRoute('/chat');
                      }
                    },
                    customBorder: const CircleBorder(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 66,
                      height: 66,
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
                            color: palette.primary.withValues(alpha: .14),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _BadgeIcon(
                        count: chatUnreadCount,
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
                selected: hasMore &&
                    (_isSelected('/atalhos/mais', currentLocation) ||
                        currentLocation == '/jogos' ||
                        currentLocation == '/listas' ||
                        currentLocation == '/localizacao'),
                onTap: () {
                  if (user == null) {
                    onLogin();
                  } else if (hasMore) {
                    context.openAppRoute('/atalhos/mais');
                  }
                },
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
                    context.openAppRoute('/perfil');
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
  if (itemPath == '/') return currentLocation == '/';
  return currentLocation == itemPath ||
      currentLocation.startsWith('$itemPath/');
}
