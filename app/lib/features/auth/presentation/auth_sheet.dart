import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_button.dart';

class AuthSheet extends StatefulWidget {
  const AuthSheet({super.key, required this.auth, required this.toast});

  final AuthController auth;
  final ToastController toast;

  @override
  State<AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<AuthSheet> {
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  bool register = false;
  bool loading = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(register ? 'Criar conta' : 'Entrar', style: const TextStyle(color: primary, fontWeight: FontWeight.w800, fontSize: 24)),
          const SizedBox(height: 12),
          if (register) TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome')),
          TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: password, decoration: const InputDecoration(labelText: 'Senha'), obscureText: true),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 22),
          SizedBox(width: double.infinity, child: AppButton(onPressed: _submit, loading: loading, label: register ? 'Cadastrar' : 'Entrar')),
          const SizedBox(height: 14),
          TextButton(onPressed: () => setState(() => register = !register), child: Text(register ? 'Já tenho conta' : 'Criar conta')),
          const SizedBox(height: 8),
          TextButton(onPressed: loading ? null : _forgotPassword, child: const Text('Esqueci minha senha')),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (register) {
        await widget.auth.register(email.text, password.text, name.text);
        widget.toast.success('Cadastro realizado com sucesso.');
      } else {
        await widget.auth.signIn(email.text, password.text);
        widget.toast.success('Login realizado com sucesso.');
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      widget.toast.error(_cleanError(e));
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await widget.auth.forgotPassword(email.text);
      widget.toast.info('Se o email existir, você receberá instruções.');
      if (mounted) setState(() => error = 'Se o email existir, você receberá instruções.');
    } catch (e) {
      widget.toast.error(_cleanError(e));
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
