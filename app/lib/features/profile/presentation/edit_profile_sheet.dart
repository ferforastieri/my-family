import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_sheet.dart';

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
      widget.toast.backendSuccess(widget.auth.takeMessage());
      if (mounted) Navigator.pop(context);
    } catch (error) {
      widget.toast.error(error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.auth.user;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSheetHeader(
            title: 'Editar perfil',
            subtitle: 'Atualize como seu nome aparece no app.',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _name,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(labelText: context.tr('Nome')),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 10),
          if (user != null)
            Text(user.email,
                style: TextStyle(color: Theme.of(context).hintColor)),
          const SizedBox(height: 18),
          AppSheetActions(
            onCancel: _saving ? null : () => Navigator.pop(context),
            onSave: _saving ? null : _save,
            loading: _saving,
          ),
        ],
      ),
    );
  }
}
