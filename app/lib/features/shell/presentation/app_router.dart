import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/chat/chat_controller.dart';
import '../../../core/notifications/notifications_controller.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../data/family_repository.dart';
import '../../admin/presentation/admin_page.dart';
import '../../chat/presentation/chat_page.dart';
import '../../content/presentation/editable_text_collection_page.dart';
import '../../games/presentation/games_page.dart';
import '../../home/presentation/home_page.dart';
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
      if (_requiresAuth(state.uri.path) && auth.user == null) return '/perfil';
      if (state.uri.path == '/admin' && auth.user?.role != 'admin') return '/';
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
                if (auth.user != null)
                  const MobileOptionItem(
                    label: 'Memórias em Fotos',
                    description: 'Fotos, vídeos e álbuns da família.',
                    path: '/galeria',
                    icon: Icons.photo_library_outlined,
                  ),
                const MobileOptionItem(
                  label: 'Nossa Playlist',
                  description: 'Músicas que marcaram nossa história.',
                  path: '/playlist',
                  icon: Icons.music_note_outlined,
                ),
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
            pageBuilder: (context, state) => _page(const MobileOptionsPage(
              title: 'Mais opções',
              items: [
                MobileOptionItem(
                  label: 'Jogos do Amor',
                  description: 'Quiz e Caça Palavras em um só lugar.',
                  path: '/jogos',
                  icon: Icons.sports_esports_outlined,
                ),
              ],
            )),
          ),
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => _page(HomePage(onNavigate: (path) {
              toast.info('Abrindo página...');
              context.go(path);
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
      path == '/galeria' ||
      path == '/playlist' ||
      path == '/carta-de-amor';
}

Page<void> _page(Widget child) {
  return NoTransitionPage<void>(child: child);
}
