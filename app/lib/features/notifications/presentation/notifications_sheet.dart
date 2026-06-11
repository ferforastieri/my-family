import 'package:flutter/material.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/notifications/notifications_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/skeleton.dart';

class NotificationsSheet extends StatelessWidget {
  const NotificationsSheet({super.key, required this.notifications});

  final NotificationsController notifications;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
      child: ListenableBuilder(
        listenable: notifications,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Notificações',
                        style: TextStyle(
                            color: palette.primary,
                            fontSize: 24,
                            fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (!notifications.pushReady)
                Text(
                  notifications.pushError ??
                      'Este aparelho ainda não está registrado para receber notificações.',
                  style: TextStyle(
                      color: palette.muted, fontWeight: FontWeight.w700),
                ),
              const SizedBox(height: 12),
              Flexible(
                child: RefreshIndicator(
                  onRefresh: notifications.refresh,
                  child: notifications.loading
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          shrinkWrap: true,
                          children: const [PageSkeleton(cards: 3)],
                        )
                      : notifications.notifications.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              shrinkWrap: true,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 22),
                                  child: Text(
                                    'Nenhuma notificação por enquanto.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: palette.muted),
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: notifications.notifications.length,
                              separatorBuilder: (_, __) =>
                                  Divider(color: palette.border),
                              itemBuilder: (context, index) {
                                final item = notifications.notifications[index];
                                return ListTile(
                                  leading: Icon(
                                    item.read
                                        ? Icons.notifications_none_outlined
                                        : Icons.notifications_active_outlined,
                                    color: item.read
                                        ? palette.muted
                                        : palette.primary,
                                  ),
                                  title: Text(item.title,
                                      style: TextStyle(
                                        color: palette.foreground,
                                        fontWeight: item.read
                                            ? FontWeight.w700
                                            : FontWeight.w900,
                                      )),
                                  subtitle: item.body.isEmpty
                                      ? null
                                      : Text(item.body),
                                  onTap: () async {
                                    await notifications.markRead(item);
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                    context.openAppRoute(item.url);
                                  },
                                );
                              },
                            ),
                ),
              ),
              const SizedBox(height: 14),
              AppButton(
                onPressed: notifications.configurePush,
                label: notifications.pushReady ? 'Push ativo' : 'Ativar push',
                icon: notifications.pushReady
                    ? Icons.check
                    : Icons.notifications_active_outlined,
              ),
            ],
          );
        },
      ),
    );
  }
}
