import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../data/family_repository.dart';
import '../../admin/presentation/admin_page.dart';
import '../../games/presentation/games_page.dart';
import '../../home/presentation/home_page.dart';
import '../../messages/presentation/messages_page.dart';
import '../../profile/presentation/profile_page.dart';
import '../../resources/presentation/resource_page.dart';
import '../../story/presentation/story_page.dart';
import 'app_shell.dart';

GoRouter buildRouter(AuthController auth, FamilyRepository repository) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      if (state.uri.path == '/admin' && auth.user?.role != 'admin') return '/';
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(
          auth: auth,
          currentLocation: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => _page(HomePage(onNavigate: context.go)),
          ),
          GoRoute(
            path: '/nossa-historia',
            pageBuilder: (context, state) => _page(const StoryPage()),
          ),
          GoRoute(
            path: '/mensagens',
            pageBuilder: (context, state) => _page(const MessagesPage()),
          ),
          GoRoute(
            path: '/carta-de-amor',
            pageBuilder: (context, state) => _page(ResourcePage(title: 'Carta de Amor', resource: 'cartas', repository: repository)),
          ),
          GoRoute(
            path: '/playlist',
            pageBuilder: (context, state) => _page(ResourcePage(title: 'Nossa Playlist', resource: 'musicas', repository: repository)),
          ),
          GoRoute(
            path: '/galeria',
            pageBuilder: (context, state) => _page(ResourcePage(title: 'Memórias em Fotos', resource: 'fotos', repository: repository)),
          ),
          GoRoute(
            path: '/jogos',
            pageBuilder: (context, state) => _page(const GamesPage()),
          ),
          GoRoute(
            path: '/quiz-do-amor',
            pageBuilder: (context, state) => _page(const GamesPage()),
          ),
          GoRoute(
            path: '/caca-palavras',
            pageBuilder: (context, state) => _page(const GamesPage()),
          ),
          GoRoute(
            path: '/flor-para-esposa',
            pageBuilder: (context, state) => _page(const MessagesPage()),
          ),
          GoRoute(
            path: '/perfil',
            pageBuilder: (context, state) => _page(ProfilePage(auth: auth)),
          ),
          GoRoute(
            path: '/admin',
            pageBuilder: (context, state) => _page(AdminPage(auth: auth)),
          ),
        ],
      ),
    ],
  );
}

Page<void> _page(Widget child) {
  return NoTransitionPage<void>(child: child);
}

