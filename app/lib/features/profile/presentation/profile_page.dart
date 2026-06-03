import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/love_background.dart';
import '../../auth/presentation/auth_sheet.dart';
import 'edit_profile_sheet.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.auth,
    required this.toast,
  });

  final AuthController auth;
  final ToastController toast;

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
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_circle_outlined,
                            size: 64, color: primary),
                        const SizedBox(height: 16),
                        const Text('Entre para ver seu perfil.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: muted)),
                        const SizedBox(height: 18),
                        AppButton(
                          onPressed: () => showAppSheet<void>(
                            context: context,
                            builder: (_) => AuthSheet(auth: auth, toast: toast),
                          ),
                          label: 'Entrar',
                          icon: Icons.login,
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: primary.withValues(alpha: .16),
                          foregroundColor: primary,
                          child: Text(_initialFor(user.name ?? user.email),
                              style: const TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(height: 16),
                        Text(user.name ?? 'Sem nome',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 22)),
                        const SizedBox(height: 6),
                        Text(user.email,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: muted)),
                        Text('Role: ${user.role}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: muted)),
                        const SizedBox(height: 24),
                        _ProfileActionTile(
                          icon: Icons.person_outline,
                          label: 'Editar perfil',
                          onTap: () => showAppSheet<void>(
                            context: context,
                            builder: (_) =>
                                EditProfileSheet(auth: auth, toast: toast),
                          ),
                        ),
                        if (user.role == 'admin') ...[
                          const SizedBox(height: 10),
                          _ProfileActionTile(
                            icon: Icons.admin_panel_settings_outlined,
                            label: 'Administração',
                            onTap: () => context.go('/admin'),
                          ),
                        ],
                        const SizedBox(height: 10),
                        _ProfileActionTile(
                          icon: Icons.logout,
                          label: 'Sair',
                          destructive: true,
                          onTap: () async {
                            await auth.signOut();
                            toast.success('Você saiu da conta.');
                            if (context.mounted) context.go('/');
                          },
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.redAccent : primary;
    return Material(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
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
