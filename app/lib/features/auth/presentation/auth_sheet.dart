import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/app_colors.dart';

class AuthSheet extends StatefulWidget {
  const AuthSheet({super.key, required this.auth});

  final AuthController auth;

  @override
  State<AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<AuthSheet> {
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  bool register = false;
  bool loading = false;

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
          const SizedBox(height: 16),
          FilledButton(onPressed: loading ? null : _submit, child: Text(register ? 'Cadastrar' : 'Entrar')),
          TextButton(onPressed: () => setState(() => register = !register), child: Text(register ? 'Já tenho conta' : 'Criar conta')),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => loading = true);
    try {
      if (register) {
        await widget.auth.register(email.text, password.text, name.text);
      } else {
        await widget.auth.signIn(email.text, password.text);
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}

