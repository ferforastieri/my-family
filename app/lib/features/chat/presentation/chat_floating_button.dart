import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

class ChatFloatingButton extends StatelessWidget {
  const ChatFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Positioned(
      left: 18,
      bottom: 18,
      child: FloatingActionButton.extended(
        heroTag: 'global-chat',
        onPressed: () => context.go('/chat'),
        backgroundColor: palette.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Chat'),
      ),
    );
  }
}
