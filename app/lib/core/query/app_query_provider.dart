import 'package:flutter/widgets.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery_core/fquery_core.dart';

class AppQueryProvider extends StatefulWidget {
  const AppQueryProvider({super.key, required this.child});

  final Widget child;

  @override
  State<AppQueryProvider> createState() => _AppQueryProviderState();
}

class _AppQueryProviderState extends State<AppQueryProvider> {
  late final QueryCache cache = QueryCache(
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
  Widget build(BuildContext context) {
    return CacheProvider(cache: cache, child: widget.child);
  }
}
