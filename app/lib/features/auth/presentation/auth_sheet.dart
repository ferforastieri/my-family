import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_sheet.dart';

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
  final familyName = TextEditingController();
  final slug = TextEditingController();
  bool register = false;
  bool loading = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSheetHeader(
            title: register ? 'Criar conta' : 'Entrar',
            subtitle: register
                ? 'Crie seu acesso para participar das memórias.'
                : 'Entre para acessar fotos, perfil e recursos privados.',
            icon: register ? Icons.person_add_alt_1_outlined : Icons.login,
          ),
          const SizedBox(height: 16),
          if (register) ...[
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nome'),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: familyName,
              decoration: const InputDecoration(labelText: 'Nome da família'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: slug,
              decoration: const InputDecoration(
                labelText: 'Endereço desejado',
                hintText: 'familia-silva',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: email,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: password,
            decoration: const InputDecoration(labelText: 'Senha'),
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 22),
          AppButton(
            onPressed: _submit,
            loading: loading,
            icon: register ? Icons.favorite_outline : Icons.login,
            label: register ? 'Cadastrar' : 'Entrar',
          ),
          const SizedBox(height: 14),
          TextButton(
              onPressed: () => setState(() => register = !register),
              child: Text(register ? 'Já tenho conta' : 'Criar conta')),
          const SizedBox(height: 8),
          TextButton(
              onPressed: loading ? null : _forgotPassword,
              child: const Text('Esqueci minha senha')),
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
        await widget.auth.register(
          email.text,
          password.text,
          name.text,
          familyName.text,
          slug: slug.text,
        );
        widget.toast.backendSuccess(widget.auth.takeMessage());
      } else {
        await widget.auth.signIn(email.text, password.text);
        widget.toast.backendSuccess(widget.auth.takeMessage());
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      final message = authErrorMessage(e);
      widget.toast.error(message);
      if (mounted) setState(() => error = message);
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
      widget.toast.backendInfo(widget.auth.takeMessage());
      if (mounted) {
        setState(() => error = 'Se o email existir, você receberá instruções.');
      }
    } catch (e) {
      final message = authErrorMessage(e);
      widget.toast.error(message);
      if (mounted) setState(() => error = message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}
