import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_navigation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/love_action_card.dart';
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          return RefreshIndicator(
            onRefresh: auth.refreshMe,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                compact ? 16 : 28,
                compact ? 10 : 14,
                compact ? 16 : 28,
                116,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AppPageHeader(
                          title: 'Perfil',
                          subtitle: 'Conta, avatar e opções do app.',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 14),
                        user == null
                            ? _GuestProfileCard(
                                onLogin: () => showAppSheet<void>(
                                  context: context,
                                  builder: (_) =>
                                      AuthSheet(auth: auth, toast: toast),
                                ),
                              )
                            : _SignedProfileCard(
                                auth: auth,
                                toast: toast,
                                onEditProfile: () => showAppSheet<void>(
                                  context: context,
                                  builder: (_) => EditProfileSheet(
                                      auth: auth, toast: toast),
                                ),
                                onAdmin: () => context.openAppRoute('/admin'),
                                onSignOut: () async {
                                  await auth.signOut();
                                  toast.success(
                                      auth.takeMessage('Sessão encerrada.'));
                                  if (context.mounted) context.go('/');
                                },
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SignedProfileCard extends StatefulWidget {
  const _SignedProfileCard({
    required this.auth,
    required this.toast,
    required this.onEditProfile,
    required this.onAdmin,
    required this.onSignOut,
  });

  final AuthController auth;
  final ToastController toast;
  final VoidCallback onEditProfile;
  final VoidCallback onAdmin;
  final VoidCallback onSignOut;

  @override
  State<_SignedProfileCard> createState() => _SignedProfileCardState();
}

class _SignedProfileCardState extends State<_SignedProfileCard> {
  bool uploadingAvatar = false;

  Future<void> _changeAvatar() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1400,
    );
    if (file == null) return;
    setState(() => uploadingAvatar = true);
    try {
      await widget.auth.updateAvatar(file);
      widget.toast.backendSuccess(widget.auth.takeMessage());
    } catch (error) {
      widget.toast.error(error.toString());
    } finally {
      if (mounted) setState(() => uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final user = widget.auth.user!;
    final displayName =
        user.name?.trim().isNotEmpty == true ? user.name!.trim() : 'Sem nome';
    return LovePanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileHero(
            displayName: displayName,
            email: user.email,
            role: user.role,
            initial: _initialFor(user.name ?? user.email),
            avatarPath: user.avatarPath,
            uploadingAvatar: uploadingAvatar,
            onChangeAvatar: _changeAvatar,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _StatusChip(
                      icon: Icons.verified_user_outlined,
                      label: user.role == 'admin' ? 'Administrador' : 'Perfil',
                    ),
                    _StatusChip(
                      icon: Icons.lock_outline,
                      label: 'Conta conectada',
                    ),
                    _StatusChip(
                      icon: Icons.favorite_outline,
                      label: 'Nossa Família',
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  'Conta',
                  style: TextStyle(
                    color: palette.foreground,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _ProfileActionTile(
                  icon: Icons.person_outline,
                  label: 'Editar perfil',
                  description: 'Atualize seu nome e suas informações.',
                  onTap: widget.onEditProfile,
                ),
                if (user.role == 'admin') ...[
                  const SizedBox(height: 10),
                  _ProfileActionTile(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Administração',
                    description: 'Gerencie usuários, notificações e jogos.',
                    onTap: widget.onAdmin,
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  'Sessão',
                  style: TextStyle(
                    color: palette.foreground,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _ProfileActionTile(
                  icon: Icons.logout,
                  label: 'Sair',
                  description: 'Encerrar sua sessão neste dispositivo.',
                  destructive: true,
                  onTap: widget.onSignOut,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestProfileCard extends StatelessWidget {
  const _GuestProfileCard({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return LovePanel(
      padding: const EdgeInsets.all(24),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: .12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: palette.primary.withValues(alpha: .22),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.account_circle_outlined,
                color: palette.primary,
                size: 56,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Seu espaço da família',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.primary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Entre para acessar memórias, perfil, administração e conversas privadas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.muted, height: 1.45),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                onPressed: onLogin,
                label: 'Entrar',
                icon: Icons.login,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.displayName,
    required this.email,
    required this.role,
    required this.initial,
    required this.avatarPath,
    required this.uploadingAvatar,
    required this.onChangeAvatar,
  });

  final String displayName;
  final String email;
  final String role;
  final String initial;
  final String? avatarPath;
  final bool uploadingAvatar;
  final VoidCallback onChangeAvatar;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.primary.withValues(alpha: .18),
            palette.primaryDark.withValues(alpha: .08),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: palette.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.primary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: palette.primary.withValues(alpha: .18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: avatarPath?.isNotEmpty == true
                    ? Image.network(
                        _avatarUrl(avatarPath!),
                        width: 82,
                        height: 82,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _InitialAvatar(
                          initial: initial,
                          color: palette.primary,
                        ),
                      )
                    : _InitialAvatar(initial: initial, color: palette.primary),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Material(
                  color: palette.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: uploadingAvatar ? null : onChangeAvatar,
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: uploadingAvatar
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.photo_camera_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.foreground,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: palette.muted),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: palette.card.withValues(alpha: .74),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: palette.border),
                      ),
                      child: Text(
                        role,
                        style: TextStyle(
                          color: palette.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: uploadingAvatar ? null : onChangeAvatar,
                      icon: const Icon(Icons.photo_camera_outlined, size: 16),
                      label: const Text('Alterar foto'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.initial, required this.color});

  final String initial;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      initial,
      style: TextStyle(
        color: color,
        fontSize: 30,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: palette.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: palette.primary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.redAccent : primary;
    return LoveActionCard(
      title: label,
      description: description,
      icon: icon,
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      trailing: Icon(Icons.chevron_right, color: color),
    );
  }
}

String _initialFor(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.substring(0, 1).toUpperCase();
}

String _avatarUrl(String path) {
  return AppConfig.apiUri('/auth/avatar?path=${Uri.encodeQueryComponent(path)}')
      .toString();
}
