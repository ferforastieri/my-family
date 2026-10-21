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
import '../../../core/widgets/home_scene.dart';
import 'package:family_ui/family_ui.dart';
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
            body: Builder(
              builder: (shellContext) => AppHeaderActionsScope(
                onNotifications: () => _openNotificationsSheet(shellContext),
                onTheme: () => _openThemeSheet(shellContext),
                onNavigation: () => _openNavigationSheet(shellContext),
                notificationCount: notifications.badgeCount,
                child: child,
              ),
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
      title: Stack(
        alignment: Alignment.center,
        children: [
          _DesktopMainNavigation(
            auth: auth,
            chatUnreadCount: chat.unreadCount,
            currentLocation: currentLocation,
            onLogin: () => _openLogin(context),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _openNotificationsSheet(context),
                  icon: _BadgeIcon(
                    count: notifications.badgeCount,
                    child: const Icon(FamilyIcons.notificationsOutlined),
                  ),
                  tooltip: 'Notificações',
                ),
                const SizedBox(width: 14),
              ],
            ),
          ),
        ],
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1),
      ),
    );
  }

  void _openNavigationSheet(BuildContext context) {
    showAppSheet<void>(
      context: context,
      builder: (_) => _NavigationSheet(
        auth: auth,
        currentLocation: currentLocation,
        onLogin: () => _openLogin(context),
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

class _NavigationSheet extends StatelessWidget {
  const _NavigationSheet({
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
    final user = auth.user;
    final hasMemories = user?.canAccess('memorias') == true ||
        user?.canAccess('playlist') == true ||
        user?.canAccess('cartas') == true ||
        user?.canAccess('nossaHistoria') == true;
    final hasMore = user?.canAccess('jogos') == true ||
        user?.canAccess('listas') == true ||
        user?.canAccess('notas') == true ||
        user?.canAccess('localizacao') == true;

    void navigate(String path) {
      Navigator.of(context).pop();
      context.openAppRoute(path);
    }

    void requireAccess(bool allowed, String path) {
      if (user == null) {
        Navigator.of(context).pop();
        onLogin();
      } else if (allowed) {
        navigate(path);
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: palette.card,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: palette.primary.withValues(alpha: .24),
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/brand/family-logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sião',
                      style: TextStyle(
                        color: palette.foreground,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _NavigationSheetItem(
                icon: FamilyIcons.homeOutlined,
                label: 'Início',
                selected: currentLocation == '/',
                onTap: () => navigate('/'),
              ),
              _NavigationSheetItem(
                icon: FamilyIcons.photoLibraryOutlined,
                label: 'Memórias',
                selected: _isSelected('/atalhos/memorias', currentLocation),
                enabled: user == null || hasMemories,
                onTap: () => requireAccess(hasMemories, '/atalhos/memorias'),
              ),
              _NavigationSheetItem(
                icon: FamilyIcons.chatBubbleOutline,
                label: 'Conversas',
                selected: _isSelected('/chat', currentLocation),
                enabled: user == null || user.canAccess('chat'),
                onTap: () =>
                    requireAccess(user?.canAccess('chat') == true, '/chat'),
              ),
              _NavigationSheetItem(
                icon: FamilyIcons.appsOutlined,
                label: 'Mais',
                selected: _isSelected('/atalhos/mais', currentLocation),
                enabled: user == null || hasMore,
                onTap: () => requireAccess(hasMore, '/atalhos/mais'),
              ),
              _NavigationSheetItem(
                icon: FamilyIcons.personOutline,
                label: 'Perfil',
                selected: _isSelected('/perfil', currentLocation),
                onTap: () => requireAccess(user != null, '/perfil'),
              ),
              if (user?.isAdmin == true) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(),
                ),
                _NavigationSheetItem(
                  icon: FamilyIcons.adminPanelSettingsOutlined,
                  label: 'Administração',
                  selected: _isSelected('/admin', currentLocation),
                  onTap: () => navigate('/admin'),
                ),
              ],
            ],
          ),
    );
  }
}

class _NavigationSheetItem extends StatelessWidget {
  const _NavigationSheetItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final color = selected ? palette.primary : palette.foreground;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        enabled: enabled,
        selected: selected,
        selectedTileColor: palette.primary.withValues(alpha: .09),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon, color: color),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        onTap: enabled ? onTap : null,
      ),
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
        user?.canAccess('notas') == true ||
        user?.canAccess('localizacao') == true;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _DesktopNavPill(
                  icon: FamilyIcons.homeOutlined,
            selectedIcon: FamilyIcons.home,
            label: 'Início',
            selected: currentLocation == '/',
            onTap: () => context.openAppRoute('/'),
          ),
          _DesktopNavPill(
            icon: FamilyIcons.photoLibraryOutlined,
            selectedIcon: FamilyIcons.photoLibrary,
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
              ],
            ),
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
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _DesktopNavPill(
                  icon: FamilyIcons.appsOutlined,
                  selectedIcon: FamilyIcons.apps,
            label: 'Mais',
            selected: hasMore &&
                (_isSelected('/atalhos/mais', currentLocation) ||
                    currentLocation == '/jogos' ||
                    currentLocation == '/listas' ||
                    currentLocation == '/notas' ||
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
            icon: FamilyIcons.personOutline,
            selectedIcon: FamilyIcons.person,
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
      child: FamilyTextButton.icon(
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
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
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
    return ListenableBuilder(
      listenable: theme,
      builder: (context, _) {
        final palette = Theme.of(context).extension<AppPalette>()!;
        return SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Aparência',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.primary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Estas preferências são só suas e acompanham sua conta.',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.muted, height: 1.35),
          ),
          const SizedBox(height: 20),
          Text(
            'Cor',
            style: TextStyle(
              color: palette.foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final option in themePrimaryOptions)
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    theme.setPrimary(option.color);
                    toast.success('Cor ${option.label.toLowerCase()} ativada.');
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: option.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.primary.toARGB32() == option.color.toARGB32()
                            ? palette.foreground
                            : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: theme.primary.toARGB32() == option.color.toARGB32()
                        ? const Icon(FamilyIcons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Cenário da Home',
            style: TextStyle(
              color: palette.foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in HomeScene.values)
                FamilyChip(
                  label: option.label,
                  icon: option.icon,
                  selected: theme.scene == option,
                  onTap: () {
                    theme.setScene(option);
                    toast.success('Cenário ${option.label.toLowerCase()} ativado.');
                  },
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Fonte',
            style: TextStyle(
              color: palette.foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<AppFontChoice>(
            segments: const [
              ButtonSegment(
                value: AppFontChoice.moderna,
                label: Text('Moderna'),
              ),
              ButtonSegment(
                value: AppFontChoice.logo,
                label: Text('Clássica'),
              ),
            ],
            selected: {theme.font},
            onSelectionChanged: (value) {
              theme.setFont(value.first);
              toast.success('Fonte atualizada.');
            },
          ),
          const SizedBox(height: 18),
          Text(
            'Modo',
            style: TextStyle(
              color: palette.foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(FamilyIcons.lightModeOutlined),
                label: Text('Claro'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(FamilyIcons.darkModeOutlined),
                label: Text('Escuro'),
              ),
            ],
            selected: {theme.mode},
            onSelectionChanged: (value) {
              theme.setMode(value.first);
              toast.success(
                value.first == ThemeMode.dark
                    ? 'Modo escuro ativado.'
                    : 'Modo claro ativado.',
              );
            },
              ),
            ],
          ),
        );
      },
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
        user?.canAccess('notas') == true ||
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
                icon: FamilyIcons.homeOutlined,
                selectedIcon: FamilyIcons.home,
                label: 'Início',
                selected: currentLocation == '/',
                onTap: () => context.openAppRoute('/'),
              ),
              _MobileNavButton(
                icon: FamilyIcons.photoLibraryOutlined,
                selectedIcon: FamilyIcons.photoLibrary,
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
                icon: FamilyIcons.appsOutlined,
                selectedIcon: FamilyIcons.apps,
                label: 'Mais',
                selected: hasMore &&
                    (_isSelected('/atalhos/mais', currentLocation) ||
                        currentLocation == '/jogos' ||
                        currentLocation == '/listas' ||
                        currentLocation == '/notas' ||
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
                icon: FamilyIcons.personOutline,
                selectedIcon: FamilyIcons.person,
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
          subtitle: 'Escolha uma opção.',
          icon: FamilyIcons.favoriteOutline,
        ),
        headerGap: 22,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FamilyActionCard(
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
        Positioned(right: -7, top: -7, child: _BadgeLabel(count: count)),
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
