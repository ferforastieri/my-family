import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_button.dart';

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key, required this.auth, required this.toast});

  final AuthController auth;
  final ToastController toast;

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _name;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.auth.user?.name ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.auth.updateMe(name: _name.text.trim());
      widget.toast.success('Perfil atualizado.');
      if (mounted) Navigator.pop(context);
    } catch (error) {
      widget.toast.error(error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final user = widget.auth.user;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Editar perfil',
              style: TextStyle(
                  color: palette.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          TextField(
            controller: _name,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Nome'),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 10),
          if (user != null)
            Text(user.email, style: TextStyle(color: palette.muted)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  onPressed: _save,
                  label: 'Salvar',
                  icon: Icons.check,
                  loading: _saving,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
