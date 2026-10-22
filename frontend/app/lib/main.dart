import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/auth/auth_controller.dart';
import 'core/config/app_config.dart';
import 'core/chat/chat_controller.dart';
import 'core/location/location_controller.dart';
import 'core/notifications/notifications_controller.dart';
import 'core/query/app_query_provider.dart';
import 'core/socket/socket_client.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/widgets/app_brand.dart';
import 'core/widgets/skeleton.dart';
import 'core/toast/toast_controller.dart';
import 'core/toast/toast_overlay.dart';
import 'data/family_repository.dart';
import 'features/shell/presentation/app_router.dart';

Future<void> main() async {
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
  final auth = AuthController(socket);
  final repository = FamilyRepository(socket);
  final chat = ChatController(socket, repository);
  final notifications = NotificationsController(socket);
  final location = LocationController(socket, auth);
  final theme = ThemeController();
  final toast = ToastController();
  final queryReset = ValueNotifier(0);
  String? lastUserId;
  String? lastPreferencesUserId;
  await auth.restoreCachedUser();
  await theme.bootstrap();
  runApp(AppQueryProvider(
    resetListenable: queryReset,
    child: MyFamilyApp(
        auth: auth,
        notifications: notifications,
        chat: chat,
        theme: theme,
        toast: toast,
        location: location,
        repository: repository),
  ));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future<void>(() async {
      await notifications.requestStartupPermissions();
      await location.requestStartupPermissions();
    }).catchError((_) {});
  });

  var protectedServicesStarted = false;
  Future<void> startProtectedServices() async {
    if (auth.user == null) return;
    if (protectedServicesStarted) {
      unawaited(notifications.ensureDeviceRegistered());
      return;
    }
    protectedServicesStarted = true;
    unawaited(notifications.bootstrap().catchError((_) {}));
    unawaited(location.bootstrap().catchError((_) {}));
    unawaited(chat.bootstrap().catchError((_) {}));
  }

  theme.savePreferences = ({
    String? primaryColor,
    String? fontFamily,
    String? themeMode,
    String? homeScene,
  }) =>
      repository
          .updatePreferences(
            primaryColor: primaryColor,
            fontFamily: fontFamily,
            themeMode: themeMode,
            homeScene: homeScene,
          )
          .then((_) {});

  auth.addListener(() {
    final userId = auth.user?.id;
    if (userId != lastUserId) {
      lastUserId = userId;
      if (userId == null) protectedServicesStarted = false;
      queryReset.value++;
    }
    if (userId != lastPreferencesUserId) {
      lastPreferencesUserId = userId;
      if (userId == null) {
        theme.reset();
      } else {
        unawaited(
          repository
              .getPreferences()
              .then(theme.applyPreferences)
              .catchError((_) {}),
        );
      }
    }
    unawaited(startProtectedServices());
  });

  Future<void>(() async {
    await auth.bootstrap();
    unawaited(startProtectedServices());
  }).catchError((_) {});
}


class MyFamilyApp extends StatelessWidget {
  const MyFamilyApp({
    super.key,
    required this.auth,
    required this.notifications,
    required this.chat,
    required this.theme,
    required this.toast,
    required this.location,
    required this.repository,
  });

  final AuthController auth;
  final NotificationsController notifications;
  final ChatController chat;
  final ThemeController theme;
  final ToastController toast;
  final LocationController location;
  final FamilyRepository repository;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([auth, theme]),
      builder: (context, _) {
        if (auth.loading) {
          return MaterialApp(
            title: 'Sião',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(
              color: theme.color,
              mode: theme.mode,
              font: theme.font,
              primary: theme.primary,
            ),
            builder: (context, child) => _AppTextScale(
              child: child ?? const SizedBox.shrink(),
            ),
            home: ToastOverlay(
              controller: toast,
              child: const _SystemSafeArea(child: _BootSplash()),
            ),
          );
        }
        return AppBrandScope(
          auth: auth,
          child: MaterialApp.router(
          title: 'Sião',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(
            color: theme.color,
            mode: theme.mode,
            font: theme.font,
            primary: theme.primary,
          ),
          routerConfig:
              buildRouter(
                auth,
                notifications,
                chat,
                theme,
                toast,
                repository,
                location,
              ),
          builder: (context, child) => _AppTextScale(
            child: ToastOverlay(
              controller: toast,
              child: _SystemSafeArea(child: child ?? const SizedBox.shrink()),
            ),
          ),
        ),
        );
      },
    );
  }
}

class _BootSplash extends StatelessWidget {
  const _BootSplash();

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return ColoredBox(
      color: palette.bgStart,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              AppConfig.apiUri('/public/branding/logo').toString(),
              width: 96,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/brand/family-logo.png',
                width: 96,
              ),
            ),
            const SizedBox(height: 20),
            const SkeletonBox(width: 120, height: 12, borderRadius: 999),
          ],
        ),
      ),
    );
  }
}

class _AppTextScale extends StatelessWidget {
  const _AppTextScale({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final textScaler = mediaQuery.textScaler.clamp(
      minScaleFactor: .9,
      maxScaleFactor: 1.3,
    );
    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: textScaler),
      child: child,
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
