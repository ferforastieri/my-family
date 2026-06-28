import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension AppNavigation on BuildContext {
  void openAppRoute(String path) {
    final current = GoRouterState.of(this).uri.path;
    if (current == path) return;
    if (path == '/home') {
      go(path);
      return;
    }
    push(path);
  }
}
