import 'package:flutter/widgets.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery_core/fquery_core.dart';

class AppQueryProvider extends StatefulWidget {
  const AppQueryProvider({
    super.key,
    required this.child,
    this.resetListenable,
  });

  final Widget child;
  final Listenable? resetListenable;

  @override
  State<AppQueryProvider> createState() => _AppQueryProviderState();
}

class _AppQueryProviderState extends State<AppQueryProvider> {
  late QueryCache cache = _createCache();

  QueryCache _createCache() => QueryCache(
        defaultQueryOptions: DefaultQueryOptions(
          enabled: true,
          refetchOnMount: RefetchOnMount.stale,
          staleDuration: const Duration(seconds: 20),
          cacheDuration: const Duration(minutes: 10),
          retryCount: 2,
          retryDelay: const Duration(seconds: 2),
        ),
      );

  @override
  void initState() {
    super.initState();
    widget.resetListenable?.addListener(_resetCache);
  }

  @override
  void didUpdateWidget(covariant AppQueryProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetListenable == widget.resetListenable) return;
    oldWidget.resetListenable?.removeListener(_resetCache);
    widget.resetListenable?.addListener(_resetCache);
  }

  @override
  void dispose() {
    widget.resetListenable?.removeListener(_resetCache);
    super.dispose();
  }

  void _resetCache() {
    if (!mounted) return;
    setState(() => cache = _createCache());
  }

  @override
  Widget build(BuildContext context) {
    return CacheProvider(cache: cache, child: widget.child);
  }
}
