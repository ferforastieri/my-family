import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/auth/auth_controller.dart';
import 'core/chat/chat_controller.dart';
import 'core/auth/token_store.dart';
import 'core/location/location_controller.dart';
import 'core/notifications/notifications_controller.dart';
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
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  final socket = SocketClient();
  final auth = AuthController(socket, TokenStore());
  final repository = FamilyRepository(socket);
  final chat = ChatController(socket, repository);
  final notifications = NotificationsController(socket);
  final location = LocationController(socket);
  final theme = ThemeController();
  final toast = ToastController();
  runApp(MyFamilyApp(
      auth: auth,
      notifications: notifications,
      chat: chat,
      theme: theme,
      toast: toast,
      repository: repository));
  unawaited(location.bootstrap());
  Future<void>(() async {
    await auth.bootstrap();
    await Future.wait([
      chat.bootstrap(),
      notifications.bootstrap(),
    ]);
  }).catchError((_) {});
  theme.bootstrap();
}

class MyFamilyApp extends StatelessWidget {
  const MyFamilyApp({
    super.key,
    required this.auth,
    required this.notifications,
    required this.chat,
    required this.theme,
    required this.toast,
    required this.repository,
  });

  final AuthController auth;
  final NotificationsController notifications;
  final ChatController chat;
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
            home: ToastOverlay(
                controller: toast,
                child: const _SystemSafeArea(child: PageSkeleton(cards: 3))),
          );
        }
        return MaterialApp.router(
          title: 'Nossa Família',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(color: theme.color, mode: theme.mode),
          routerConfig:
              buildRouter(auth, notifications, chat, theme, toast, repository),
          builder: (context, child) => ToastOverlay(
            controller: toast,
            child: _SystemSafeArea(child: child ?? const SizedBox.shrink()),
          ),
        );
      },
    );
  }
}

class _SystemSafeArea extends StatelessWidget {
  const _SystemSafeArea({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final brightness = Theme.of(context).brightness;
    final overlayStyle = brightness == Brightness.dark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: palette.bgStart,
            systemNavigationBarColor: palette.card,
            systemNavigationBarDividerColor: palette.card,
            systemStatusBarContrastEnforced: false,
            systemNavigationBarContrastEnforced: false,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: palette.bgStart,
            systemNavigationBarColor: palette.card,
            systemNavigationBarDividerColor: palette.card,
            systemStatusBarContrastEnforced: false,
            systemNavigationBarContrastEnforced: false,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: palette.bgStart),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.of(context).padding.bottom,
            child: ColoredBox(color: palette.card),
          ),
          SafeArea(
            top: true,
            bottom: true,
            left: false,
            right: false,
            child: child,
          ),
        ],
      ),
    );
  }
}
