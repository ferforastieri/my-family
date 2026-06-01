import 'package:flutter/material.dart';

import 'core/auth/auth_controller.dart';
import 'core/auth/token_store.dart';
import 'core/socket/socket_client.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/skeleton.dart';
import 'data/family_repository.dart';
import 'features/shell/presentation/app_router.dart';

void main() {
  final socket = SocketClient();
  final auth = AuthController(socket, TokenStore());
  runApp(MyFamilyApp(auth: auth, repository: FamilyRepository(socket)));
  auth.bootstrap();
}

class MyFamilyApp extends StatelessWidget {
  const MyFamilyApp({super.key, required this.auth, required this.repository});

  final AuthController auth;
  final FamilyRepository repository;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: auth,
      builder: (context, _) {
        if (auth.loading) {
          return MaterialApp(
            title: 'Nossa Família',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            home: const PageSkeleton(cards: 3),
          );
        }
        return MaterialApp.router(
          title: 'Nossa Família',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          routerConfig: buildRouter(auth, repository),
        );
      },
    );
  }
}
