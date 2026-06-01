import 'package:flutter/material.dart';

import 'core/auth/auth_controller.dart';
import 'core/auth/token_store.dart';
import 'core/socket/socket_client.dart';
import 'core/theme/app_theme.dart';
import 'data/family_repository.dart';
import 'features/shell/presentation/app_shell.dart';

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
        return MaterialApp(
          title: 'Nossa Família',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: auth.loading
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : AppShell(auth: auth, repository: repository),
        );
      },
    );
  }
}

