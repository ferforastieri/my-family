import 'package:flutter/material.dart';

import 'skeleton.dart';

/// A buttonless end-of-list sentinel. It attaches to the nearest scrollable and
/// asks for the next backend page when the user gets close to the end.
class AppInfiniteLoader extends StatefulWidget {
  const AppInfiniteLoader({
    super.key,
    required this.page,
    required this.hasMore,
    required this.onLoadMore,
    this.loading = false,
  });

  final int page;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final bool loading;

  @override
  State<AppInfiniteLoader> createState() => _AppInfiniteLoaderState();
}

class _AppInfiniteLoaderState extends State<AppInfiniteLoader> {
  ScrollPosition? position;
  bool scheduled = false;
  int? requestedForPage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (!identical(next, position)) {
      position?.removeListener(_onScroll);
      position = next;
      position?.addListener(_onScroll);
    }
    _scheduleCheck();
  }

  @override
  void didUpdateWidget(covariant AppInfiniteLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page != widget.page) requestedForPage = null;
    if (oldWidget.page != widget.page ||
        oldWidget.hasMore != widget.hasMore ||
        oldWidget.loading != widget.loading) {
      _scheduleCheck();
    }
  }

  @override
  void dispose() {
    position?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() => _scheduleCheck();

  void _scheduleCheck() {
    if (scheduled || !mounted) return;
    scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scheduled = false;
      _check();
    });
  }

  void _check() {
    if (!mounted || !widget.hasMore || widget.loading) return;
    final current = position;
    if (current == null) return;
    if (!current.hasContentDimensions) {
      _scheduleCheck();
      return;
    }
    if (current.extentAfter <= 420 && requestedForPage != widget.page) {
      requestedForPage = widget.page;
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.hasMore) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: SkeletonBox(height: 56, borderRadius: 16),
    );
  }
}
