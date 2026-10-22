import 'package:flutter/material.dart';

/// Flutter Web draws scrollbars at the edge of the scrollable content. For this
/// landing/app we use the browser's page scroll instead, so no inner scrollbar
/// should be painted over the centered layout.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
