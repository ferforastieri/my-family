import 'package:flutter/material.dart';

class AppFixedHeaderScrollView extends StatelessWidget {
  const AppFixedHeaderScrollView({
    super.key,
    required this.header,
    required this.children,
    this.maxWidth = 1200,
    this.padding = const EdgeInsets.fromLTRB(18, 10, 18, 112),
    this.headerGap = 16,
    this.onEndReached,
  });

  final Widget header;
  final List<Widget> children;
  final double maxWidth;
  final EdgeInsets padding;
  final double headerGap;
  final VoidCallback? onEndReached;

  Widget _list(Widget child) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (onEndReached != null &&
            notification.metrics.axis == Axis.vertical &&
            notification.metrics.extentAfter < 420) {
          onEndReached!();
        }
        return false;
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 860;
    if (desktop) {
      return _list(
        ListView(
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
          child: _list(
            ListView(
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

  Widget _bounded(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
