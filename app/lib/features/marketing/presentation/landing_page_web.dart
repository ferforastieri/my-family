import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../../core/auth/auth_controller.dart';
import '../../../core/config/app_config.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      web.window.location.replace(_landingUri().toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  Uri _landingUri() {
    return Uri.parse(AppConfig.publicWebUrl).replace(
      path: '/${widget.locale.code}',
    );
  }
}
