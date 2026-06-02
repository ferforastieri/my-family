import 'package:flutter/material.dart';

import 'core/auth/auth_controller.dart';
import 'core/auth/token_store.dart';
import 'core/socket/socket_client.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/toast/toast_controller.dart';
import 'core/toast/toast_overlay.dart';
import 'core/widgets/skeleton.dart';
import 'data/family_repository.dart';
import 'features/shell/presentation/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final socket = SocketClient();
  final auth = AuthController(socket, TokenStore());
  final theme = ThemeController();
  final toast = ToastController();
  runApp(MyFamilyApp(auth: auth, theme: theme, toast: toast, repository: FamilyRepository(socket)));
  auth.bootstrap();
  theme.bootstrap();
}

class MyFamilyApp extends StatelessWidget {
  const MyFamilyApp({super.key, required this.auth, required this.theme, required this.toast, required this.repository});

  final AuthController auth;
  final ThemeController theme;
  final ToastController toast;
  final FamilyRepository repository;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([auth, theme]),
      builder: (context, _) {
        if (auth.loading) {
          return MaterialApp(
            title: 'Nossa Família',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(color: theme.color, mode: theme.mode),
            home: ToastOverlay(controller: toast, child: const PageSkeleton(cards: 3)),
          );
        }
        return MaterialApp.router(
          title: 'Nossa Família',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(color: theme.color, mode: theme.mode),
          routerConfig: buildRouter(auth, theme, toast, repository),
          builder: (context, child) => ToastOverlay(controller: toast, child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
