import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/love_background.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final user = auth.user;
    return LoveBackground(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: user == null
                  ? const Text('Entre para ver seu perfil.', textAlign: TextAlign.center, style: TextStyle(color: muted))
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: primary.withValues(alpha: .16),
                          foregroundColor: primary,
                          child: Text(_initialFor(user.name ?? user.email), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(height: 16),
                        Text(user.name ?? 'Sem nome', textAlign: TextAlign.center, style: const TextStyle(color: primary, fontWeight: FontWeight.w800, fontSize: 22)),
                        const SizedBox(height: 6),
                        Text(user.email, textAlign: TextAlign.center, style: const TextStyle(color: muted)),
                        Text('Role: ${user.role}', textAlign: TextAlign.center, style: const TextStyle(color: muted)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

String _initialFor(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.substring(0, 1).toUpperCase();
}

