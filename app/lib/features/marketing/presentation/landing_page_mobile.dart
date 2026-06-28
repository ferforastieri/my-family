import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/marketing_copy.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({
    super.key,
    required this.auth,
    required this.locale,
  });

  final AuthController auth;
  final MarketingLocale locale;

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  late final WebViewController controller;
  var progress = 0;
  var loading = true;
  String? errorText;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (mounted) setState(() => progress = value);
          },
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                loading = true;
                errorText = null;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) setState(() => loading = false);
          },
          onWebResourceError: (error) {
            if (mounted && error.isForMainFrame == true) {
              setState(() {
                loading = false;
                errorText = error.description;
              });
            }
          },
          onNavigationRequest: _handleNavigation,
        ),
      )
      ..loadRequest(_landingUri());
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Scaffold(
      backgroundColor: palette.bgStart,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            WebViewWidget(controller: controller),
            if (loading || progress < 100)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: LinearProgressIndicator(
                  value: progress <= 0 ? null : progress / 100,
                  minHeight: 2,
                ),
              ),
            if (errorText != null)
              _LandingLoadError(
                message: errorText!,
                onRetry: () => controller.loadRequest(_landingUri()),
              ),
          ],
        ),
      ),
    );
  }

  Uri _landingUri() {
    return Uri.parse(AppConfig.publicWebUrl).replace(
      path: '/${widget.locale.code}',
      queryParameters: {
        'surface': 'app',
      },
    );
  }

  NavigationDecision _handleNavigation(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;
    final appRoute = _appRouteFromLandingUri(uri);
    if (appRoute == null) return NavigationDecision.navigate;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(appRoute);
    });
    return NavigationDecision.prevent;
  }
}

String? _appRouteFromLandingUri(Uri uri) {
  if (uri.path == '/app') return '/';
  if (!uri.path.startsWith('/app/')) return null;
  final routePath = uri.path.substring('/app'.length);
  return Uri(
    path: routePath.isEmpty ? '/' : routePath,
    query: uri.hasQuery ? uri.query : null,
    fragment: uri.hasFragment ? uri.fragment : null,
  ).toString();
}

class _LandingLoadError extends StatelessWidget {
  const _LandingLoadError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Positioned.fill(
      child: ColoredBox(
        color: palette.bgStart,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.public_off_outlined, size: 44),
                const SizedBox(height: 14),
                Text(
                  'Não foi possível carregar a landing.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.foreground,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.muted, height: 1.4),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
