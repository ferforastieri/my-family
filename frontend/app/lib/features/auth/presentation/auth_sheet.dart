import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/toast/toast_controller.dart';
import 'package:family_ui/family_ui.dart';
import '../../../core/widgets/app_sheet.dart';

class AuthSheet extends StatefulWidget {
  const AuthSheet({
    super.key,
    required this.auth,
    required this.toast,
    this.onAuthenticated,
    this.initialRegisterMode = false,
    this.tenantSlug,
    this.invitationToken,
  });

  final AuthController auth;
  final ToastController toast;
  final VoidCallback? onAuthenticated;
  final bool initialRegisterMode;
  final String? tenantSlug;
  final String? invitationToken;

  @override
  State<AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<AuthSheet> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  late bool registerMode;
  bool loading = false;
  bool obscurePassword = true;
  bool acceptedTerms = false;
  String? error;

  @override
  void initState() {
    super.initState();
    registerMode = widget.initialRegisterMode;
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSheetHeader(
            title: registerMode ? 'Criar conta' : 'Entrar',
            subtitle: registerMode
                ? 'Crie sua conta e comece a guardar as memórias da família.'
                : 'Acesse com seu email e senha.',
            icon: registerMode
                ? FamilyIcons.personAddAlt1Outlined
                : FamilyIcons.lockOpenOutlined,
          ),
          const SizedBox(height: 16),
          if (registerMode) ...[
            FamilyTextField(
              controller: name,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(labelText: 'Seu nome'),
            ),
            const SizedBox(height: 12),
          ],
          FamilyTextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          FamilyTextField(
            controller: password,
            obscureText: obscurePassword,
            autofillHints: [
              registerMode ? AutofillHints.newPassword : AutofillHints.password,
            ],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Senha',
              helperText: registerMode ? 'Mínimo de 8 caracteres' : null,
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => obscurePassword = !obscurePassword),
                icon: Icon(
                  obscurePassword
                      ? FamilyIcons.visibilityOutlined
                      : FamilyIcons.visibilityOffOutlined,
                ),
              ),
            ),
          ),
          if (registerMode) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 30,
                  height: 30,
                  child: Checkbox(
                    value: acceptedTerms,
                    onChanged: loading
                        ? null
                        : (value) =>
                            setState(() => acceptedTerms = value ?? false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Li e aceito os '),
                      InkWell(
                        onTap: () => _openLegal('termos'),
                        child: Text(
                          'Termos',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const Text(' e a '),
                      InkWell(
                        onTap: () => _openLegal('privacidade'),
                        child: Text(
                          'Política de privacidade',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const Text('.'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FamilyButton(
            onPressed: _submit,
            loading: loading,
            icon: registerMode ? FamilyIcons.personAddAlt : FamilyIcons.login,
            label: registerMode ? 'Criar conta' : 'Entrar',
          ),
          FamilyTextButton(
            onPressed: loading
                ? null
                : () => setState(() {
                      registerMode = !registerMode;
                      error = null;
                    }),
            child: Text(
              registerMode ? 'Já tenho conta' : 'Criar uma conta',
            ),
          ),
        ],
      ),
    );
  }

  void _openLegal(String path) {
    context.push('/$path');
  }

  Future<void> _submit() async {
    final emailValue = email.text.trim();
    final passwordValue = password.text;
    if (!emailValue.contains('@') || !emailValue.contains('.')) {
      setState(() => error = 'Informe um email válido.');
      return;
    }
    if (registerMode && passwordValue.length < 8) {
      setState(() => error = 'A senha deve ter pelo menos 8 caracteres.');
      return;
    }
    if (passwordValue.isEmpty) {
      setState(() => error = 'Informe sua senha.');
      return;
    }
    if (registerMode && name.text.trim().isEmpty) {
      setState(() => error = 'Informe seu nome.');
      return;
    }
    if (registerMode && !acceptedTerms) {
      setState(() => error = 'Aceite os termos para criar sua conta.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (registerMode) {
        await widget.auth.register(
          name.text,
          emailValue,
          passwordValue,
          tenantSlug: widget.tenantSlug,
          invitationToken: widget.invitationToken,
        );
      } else {
        await widget.auth.login(
          emailValue,
          passwordValue,
          tenantSlug: widget.tenantSlug,
        );
      }
      widget.toast.backendSuccess(widget.auth.takeMessage());
      if (widget.onAuthenticated != null) {
        widget.onAuthenticated!();
      } else if (mounted) {
        Navigator.pop(context);
      }
    } catch (exception) {
      final message = authErrorMessage(exception);
      widget.toast.error(message);
      if (mounted) setState(() => error = message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}
