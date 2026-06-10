import 'package:flutter/material.dart';

class AppFixedHeaderScrollView extends StatelessWidget {
  const AppFixedHeaderScrollView({
    super.key,
    required this.header,
    required this.children,
    this.onRefresh,
    this.maxWidth = 1200,
    this.padding = const EdgeInsets.fromLTRB(18, 10, 18, 112),
    this.headerGap = 16,
  });

  final Widget header;
  final List<Widget> children;
  final RefreshCallback? onRefresh;
  final double maxWidth;
  final EdgeInsets padding;
  final double headerGap;

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 860;
    if (desktop) {
      return _withRefresh(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding,
          children: [
            _bounded(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  SizedBox(height: headerGap),
                  ...children,
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            padding.left,
            padding.top,
            padding.right,
            0,
          ),
          child: _bounded(header),
        ),
        Expanded(
          child: _withRefresh(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                padding.left,
                headerGap,
                padding.right,
                padding.bottom,
              ),
              children: [
                _bounded(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _withRefresh({required Widget child}) {
    if (onRefresh == null) return child;
    return RefreshIndicator(onRefresh: onRefresh!, child: child);
  }

  Widget _bounded(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
