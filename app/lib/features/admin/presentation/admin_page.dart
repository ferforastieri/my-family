import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/widgets/love_background.dart';
import '../../../core/widgets/love_text_card.dart';
import '../../../core/widgets/section_title.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key, required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return LoveBackground(
      child: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SectionTitle('Administração', size: 38),
          const SizedBox(height: 32),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: const Column(
                children: [
                  LoveTextCard(title: 'Usuários', body: 'Gerenciamento via eventos users.* com permissão de admin.'),
                  LoveTextCard(title: 'Notificações', body: 'Envio, agendamento e histórico via WebSocket.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
