import 'package:flutter/material.dart';

import '../auth/auth_controller.dart';
import '../auth/authenticated_media.dart';
import '../config/app_config.dart';

/// Bumped after the global platform logo is changed, so every visible logo
/// gets a fresh URL without restarting the app.
final ValueNotifier<int> brandGlobalVersion = ValueNotifier<int>(0);

class AppBrandScope extends InheritedNotifier<AuthController> {
  const AppBrandScope({
    super.key,
    required AuthController auth,
    required super.child,
  }) : super(notifier: auth);

  static AuthController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppBrandScope>()
        ?.notifier;
  }
}

class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: brandGlobalVersion,
      builder: (context, _, __) {
        final user = AppBrandScope.maybeOf(context)?.user;
        final isFamilyLogo = user != null;
        final version = isFamilyLogo
            ? '?v=${user.tenantLogoVersion ?? 0}'
            : '?v=${brandGlobalVersion.value}';
        final path = isFamilyLogo
            ? '/tenant/branding/logo$version'
            : '/public/branding/logo$version';
        return Image.network(
          AppConfig.apiUri(path).toString(),
          width: width,
          height: height,
          fit: fit,
          headers: isFamilyLogo ? authenticatedMediaHeaders() : null,
          errorBuilder: (context, error, stackTrace) => Image.asset(
            'assets/brand/family-logo.png',
            width: width,
            height: height,
            fit: fit,
          ),
        );
      },
    );
  }
}
