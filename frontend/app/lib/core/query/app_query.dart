import 'package:flutter/material.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery_core/fquery_core.dart';

import '../widgets/app_button.dart';
import '../widgets/skeleton.dart';

class AppQuery<T> extends StatelessWidget {
  const AppQuery({
    super.key,
    required this.queryKey,
    required this.queryFn,
    required this.builder,
    this.loading,
  });

  final List<Object?> queryKey;
  final Future<T> Function() queryFn;
  final Widget? loading;
  final Widget Function(
    BuildContext context,
    T data,
    Future<void> Function() refetch,
  ) builder;

  @override
  Widget build(BuildContext context) {
    return QueryBuilder<T, Exception>(
      options: QueryOptions<T, Exception>(
        queryKey: QueryKey(queryKey),
        queryFn: queryFn,
      ),
      builder: (context, result) {
        final data = result.data;
        if (result.isLoading && data == null) {
          return loading ?? const PageSkeleton();
        }
        if (result.isError && data == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    result.error?.toString() ?? 'Erro ao carregar.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    onPressed: () async => result.refetch(),
                    label: 'Tentar novamente',
                    icon: Icons.refresh,
                  ),
                ],
              ),
            ),
          );
        }
        return builder(context, data as T, () async => result.refetch());
      },
    );
  }
}

void invalidateQueries(BuildContext context, List<Object?> queryKey) {
  CacheProvider.get(context).invalidateQueries(queryKey);
}
