import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/chat/chat_controller.dart';
import '../../../core/notifications/notifications_controller.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../data/family_repository.dart';
import '../../admin/presentation/admin_page.dart';
import '../../billing/presentation/billing_page.dart';
import '../../client_dashboard/presentation/client_dashboard_page.dart';
import '../../chat/presentation/chat_page.dart';
import '../../content/presentation/editable_text_collection_page.dart';
import '../../family_selection/presentation/family_selection_page.dart';
import '../../games/presentation/games_page.dart';
import '../../home/presentation/home_page.dart';
import '../../lists/presentation/lists_page.dart';
import '../../location/presentation/location_page.dart';
import '../../marketing/domain/marketing_copy.dart';
import '../../marketing/presentation/demo_page.dart';
import '../../marketing/presentation/public_auth_page.dart';
import '../../profile/presentation/profile_page.dart';
import '../../platform_admin/presentation/platform_admin_page.dart';
import '../../resources/presentation/resource_page.dart';
import 'app_shell.dart';

GoRouter buildRouter(
  AuthController auth,
  NotificationsController notifications,
  ChatController chat,
  ThemeController theme,
  LocaleController locale,
  ToastController toast,
  FamilyRepository repository,
) {
  return GoRouter(
    navigatorKey: notifications.navigatorKey,
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final path = state.uri.path;
      const publicPaths = {
        '/demo',
        '/signup',
        '/login/cliente',
        '/login/painel',
      };
      const familySelectionPaths = {
        '/familias',
      };
      const platformAdminPaths = {
        '/admin/plataforma',
      };
      const panelPaths = {
        '/painel',
        '/admin/familia',
        '/billing',
      };
      final platformAdminPath = platformAdminPaths.contains(path);
      final panelPath = panelPaths.contains(path) ||
          RegExp(r'^/cliente/[^/]+/assinatura$').hasMatch(path);
      final publicPath =
          publicPaths.contains(path) || _isFamilySiteLoginPath(path);
      if (auth.user == null) {
        if (platformAdminPath) {
          return Uri(
            path: '/login/painel',
            queryParameters: {'next': path},
          ).toString();
        }
        if (panelPath) return '/login/painel';
        return publicPath ? null : '/login/cliente';
      }
      if (publicPath) return null;
      if (platformAdminPath) {
        return auth.user?.isPlatformSession == true
            ? null
            : Uri(
                path: '/login/painel',
                queryParameters: {'next': path},
              ).toString();
      }
      if (auth.tenant == null) {
        if (familySelectionPaths.contains(path)) return null;
        return '/familias';
      }
      if (familySelectionPaths.contains(path)) {
        if (_safeNextPath(state.uri.queryParameters['next']) != null) {
          return null;
        }
        return auth.tenant!.isActive ? '/' : '/billing';
      }
      final accessKey = _accessForPath(path);
      if (auth.user != null &&
          auth.tenant?.isActive != true &&
          path != '/billing' &&
          path != '/perfil' &&
          !platformAdminPath) {
        return '/billing';
      }
      if (panelPath && auth.user?.isAdmin != true) {
        return '/';
      }
      if (accessKey != null && auth.user?.canAccess(accessKey) != true) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/demo',
        pageBuilder: (context, state) => _page(DemoPage(
          locale: MarketingLocale.resolve(state.uri.queryParameters['locale']),
        )),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => _page(PublicAuthPage(
          auth: auth,
          toast: toast,
          locale: MarketingLocale.resolve(state.uri.queryParameters['locale']),
          register: true,
          initialPlanInterval: state.uri.queryParameters['plan'],
        )),
      ),
      GoRoute(
        path: '/login/cliente',
        pageBuilder: (context, state) => _page(PublicAuthPage(
          auth: auth,
          toast: toast,
          locale: MarketingLocale.resolve(state.uri.queryParameters['locale']),
          register: false,
          entry: PublicAuthEntry.client,
          initialPlanInterval: state.uri.queryParameters['plan'],
        )),
      ),
      GoRoute(
        path: '/login/painel',
        pageBuilder: (context, state) => _page(PublicAuthPage(
          auth: auth,
          toast: toast,
          locale: MarketingLocale.resolve(state.uri.queryParameters['locale']),
          register: false,
          entry: PublicAuthEntry.panel,
          afterLoginPath: _safeNextPath(state.uri.queryParameters['next']) ??
              _familySelectionNext('/painel'),
        )),
      ),
      GoRoute(
        path: '/familia/:tenantSlug/login',
        pageBuilder: (context, state) => _page(PublicAuthPage(
          auth: auth,
          toast: toast,
          locale: MarketingLocale.resolve(state.uri.queryParameters['locale']),
          register: false,
          entry: PublicAuthEntry.familySite,
          tenantSlug: state.pathParameters['tenantSlug'],
          afterLoginPath: '/',
        )),
      ),
      GoRoute(
        path: '/familias',
        pageBuilder: (context, state) => _page(FamilySelectionPage(
          auth: auth,
          toast: toast,
          nextPath: _safeNextPath(state.uri.queryParameters['next']),
        )),
      ),
      GoRoute(
        path: '/admin/plataforma',
        pageBuilder: (context, state) => _page(PlatformAdminPage(auth: auth)),
      ),
      GoRoute(
        path: '/painel',
        pageBuilder: (context, state) => _page(ClientDashboardPage(auth: auth)),
      ),
      GoRoute(
        path: '/billing',
        pageBuilder: (context, state) => _page(BillingPage(
          auth: auth,
          toast: toast,
          initialPlanInterval: state.uri.queryParameters['plan'],
        )),
      ),
      GoRoute(
        path: '/cliente/:tenantSlug/assinatura',
        pageBuilder: (context, state) => _page(BillingPage(
          auth: auth,
          toast: toast,
          initialPlanInterval: state.uri.queryParameters['plan'],
        )),
      ),
      GoRoute(
        path: '/admin/familia',
        pageBuilder: (context, state) =>
            _page(AdminPage(auth: auth, repository: repository, toast: toast)),
      ),
      ShellRoute(
        builder: (context, state, child) {
          unawaited(auth.trackEvent('navigation', path: state.uri.path));
          return AppShell(
            auth: auth,
            notifications: notifications,
            chat: chat,
            theme: theme,
            locale: locale,
            toast: toast,
            currentLocation: state.uri.path,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/atalhos/memorias',
            pageBuilder: (context, state) => _page(MobileOptionsPage(
              title: 'Memórias',
              items: [
                if (auth.user?.canAccess('memorias') == true)
                  const MobileOptionItem(
                    label: 'Memórias em Fotos',
                    description: 'Fotos, vídeos e álbuns da família.',
                    path: '/galeria',
                    icon: Icons.photo_library_outlined,
                  ),
                if (auth.user?.canAccess('playlist') == true)
                  const MobileOptionItem(
                    label: 'Nossa Playlist',
                    description: 'Músicas que marcaram nossa história.',
                    path: '/playlist',
                    icon: Icons.music_note_outlined,
                  ),
                if (auth.user?.canAccess('cartas') == true)
                  const MobileOptionItem(
                    label: 'Carta de Amor',
                    description: 'Cartas e declarações especiais.',
                    path: '/carta-de-amor',
                    icon: Icons.card_giftcard_outlined,
                  ),
                if (auth.user?.canAccess('nossaHistoria') == true)
                  const MobileOptionItem(
                    label: 'Nossa Jornada',
                    description:
                        'Capítulos e registros da história da família.',
                    path: '/nossa-historia',
                    icon: Icons.menu_book_outlined,
                  ),
              ],
            )),
          ),
          GoRoute(
            path: '/atalhos/mais',
            pageBuilder: (context, state) => _page(MobileOptionsPage(
              title: 'Mais opções',
              items: [
                if (auth.user?.canAccess('jogos') == true)
                  const MobileOptionItem(
                    label: 'Jogos do Amor',
                    description: 'Jogos simples para se divertir juntos.',
                    path: '/jogos',
                    icon: Icons.sports_esports_outlined,
                  ),
                if (auth.user?.canAccess('listas') == true)
                  const MobileOptionItem(
                    label: 'Listas',
                    description: 'Compras, tarefas e combinados.',
                    path: '/listas',
                    icon: Icons.checklist_outlined,
                  ),
                if (auth.user?.canAccess('notas') == true)
                  const MobileOptionItem(
                    label: 'Notas',
                    description: 'Ideias, lembretes e registros soltos.',
                    path: '/notas',
                    icon: Icons.sticky_note_2_outlined,
                  ),
                if (auth.user?.canAccess('localizacao') == true)
                  const MobileOptionItem(
                    label: 'Localização',
                    description: 'Mapa da família e bateria de cada pessoa.',
                    path: '/localizacao',
                    icon: Icons.location_on_outlined,
                  ),
              ],
            )),
          ),
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => _page(HomePage(
              repository: repository,
              onNavigate: (path) {
                context.openAppRoute(path);
              },
            )),
          ),
          GoRoute(
            path: '/nossa-historia',
            pageBuilder: (context, state) => _page(EditableTextCollectionPage(
              title: context.tr('Nossa Jornada'),
              prefix: 'journey',
              repository: repository,
              toast: toast,
              auth: auth,
            )),
          ),
          GoRoute(
            path: '/chat',
            pageBuilder: (context, state) => _page(ChatPage(
              key: ValueKey(state.uri.toString()),
              chat: chat,
              auth: auth,
              toast: toast,
              initialConversationId:
                  state.uri.queryParameters['conversationId'],
            )),
          ),
          GoRoute(
            path: '/carta-de-amor',
            pageBuilder: (context, state) => _page(ResourcePage(
                title: 'Carta de Amor',
                resource: 'cartas',
                repository: repository,
                toast: toast)),
          ),
          GoRoute(
            path: '/playlist',
            pageBuilder: (context, state) => _page(ResourcePage(
                title: 'Nossa Playlist',
                resource: 'musicas',
                repository: repository,
                toast: toast)),
          ),
          GoRoute(
            path: '/galeria',
            pageBuilder: (context, state) => _page(ResourcePage(
                title: 'Memórias em Fotos',
                resource: 'fotos',
                repository: repository,
                toast: toast)),
          ),
          GoRoute(
            path: '/jogos',
            pageBuilder: (context, state) => _page(
                GamesPage(repository: repository, toast: toast, auth: auth)),
          ),
          GoRoute(
            path: '/listas',
            pageBuilder: (context, state) => _page(ListsPage(
              repository: repository,
              auth: auth,
              toast: toast,
            )),
          ),
          GoRoute(
            path: '/notas',
            pageBuilder: (context, state) => _page(ResourcePage(
                title: 'Notas',
                resource: 'notas',
                repository: repository,
                toast: toast)),
          ),
          GoRoute(
            path: '/localizacao',
            pageBuilder: (context, state) => _page(LocationPage(
              repository: repository,
              toast: toast,
            )),
          ),
          GoRoute(
            path: '/perfil',
            pageBuilder: (context, state) => _page(ProfilePage(
              auth: auth,
              toast: toast,
            )),
          ),
        ],
      ),
    ],
  );
}

bool _isFamilySiteLoginPath(String path) {
  return RegExp(r'^/familia/[^/]+/login$').hasMatch(path);
}

String _familySelectionNext(String nextPath) {
  return Uri(
    path: '/familias',
    queryParameters: {'next': nextPath},
  ).toString();
}

String? _safeNextPath(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final uri = Uri.tryParse(value.trim());
  if (uri == null || uri.hasScheme || uri.host.isNotEmpty) return null;
  if (!value.startsWith('/') || value.startsWith('//')) return null;
  final path = uri.path;
  if (path.startsWith('/login') ||
      path == '/signup' ||
      path == '/demo' ||
      path == '/familias') {
    return null;
  }
  return uri.replace(path: path).toString();
}

String? _accessForPath(String path) {
  return switch (path) {
    '/galeria' => 'memorias',
    '/playlist' => 'playlist',
    '/carta-de-amor' => 'cartas',
    '/jogos' => 'jogos',
    '/listas' => 'listas',
    '/notas' => 'notas',
    '/localizacao' => 'localizacao',
    '/chat' => 'chat',
    '/nossa-historia' => 'nossaHistoria',
    _ => null,
  };
}

Page<void> _page(Widget child) {
  return NoTransitionPage<void>(child: child);
}
