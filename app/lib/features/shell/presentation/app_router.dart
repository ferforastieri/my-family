import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/chat/chat_controller.dart';
import '../../../core/notifications/notifications_controller.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../data/family_repository.dart';
import '../../admin/presentation/admin_page.dart';
import '../../chat/presentation/chat_page.dart';
import '../../content/presentation/editable_text_collection_page.dart';
import '../../games/presentation/games_page.dart';
import '../../home/presentation/home_page.dart';
import '../../lists/presentation/lists_page.dart';
import '../../location/presentation/location_page.dart';
import '../../profile/presentation/profile_page.dart';
import '../../resources/presentation/resource_page.dart';
import 'app_shell.dart';

GoRouter buildRouter(
  AuthController auth,
  NotificationsController notifications,
  ChatController chat,
  ThemeController theme,
  ToastController toast,
  FamilyRepository repository,
) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final path = state.uri.path;
      final accessKey = _accessForPath(path);
      if ((_requiresAuth(path) || accessKey != null) && auth.user == null) {
        return '/perfil';
      }
      if (path == '/admin' && auth.user?.isAdmin != true) return '/';
      if (accessKey != null && auth.user?.canAccess(accessKey) != true) {
        return '/';
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(
          auth: auth,
          notifications: notifications,
          chat: chat,
          theme: theme,
          toast: toast,
          currentLocation: state.uri.path,
          child: child,
        ),
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
                    description: 'Quiz e Caça Palavras em um só lugar.',
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
            pageBuilder: (context, state) => _page(HomePage(onNavigate: (path) {
              context.openAppRoute(path);
            })),
          ),
          GoRoute(
            path: '/nossa-historia',
            pageBuilder: (context, state) => _page(EditableTextCollectionPage(
              title: 'Nossa Jornada',
              prefix: 'journey',
              repository: repository,
              toast: toast,
              auth: auth,
            )),
          ),
          GoRoute(
            path: '/chat',
            pageBuilder: (context, state) =>
                _page(ChatPage(chat: chat, auth: auth, toast: toast)),
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
          GoRoute(
            path: '/admin',
            pageBuilder: (context, state) => _page(
                AdminPage(auth: auth, repository: repository, toast: toast)),
          ),
        ],
      ),
    ],
  );
}

bool _requiresAuth(String path) {
  return path == '/atalhos/memorias' ||
      path == '/atalhos/mais' ||
      path == '/admin';
}

String? _accessForPath(String path) {
  return switch (path) {
    '/galeria' => 'memorias',
    '/playlist' => 'playlist',
    '/carta-de-amor' => 'cartas',
    '/jogos' => 'jogos',
    '/listas' => 'listas',
    '/localizacao' => 'localizacao',
    '/chat' => 'chat',
    '/nossa-historia' => 'nossaHistoria',
    _ => null,
  };
}

Page<void> _page(Widget child) {
  return NoTransitionPage<void>(child: child);
}
