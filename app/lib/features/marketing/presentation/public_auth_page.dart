import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/love_background.dart';
import '../domain/marketing_copy.dart';

class PublicAuthPage extends StatefulWidget {
  const PublicAuthPage({
    super.key,
    required this.auth,
    required this.toast,
    required this.locale,
    required this.register,
  });

  final AuthController auth;
  final ToastController toast;
  final MarketingLocale locale;
  final bool register;

  @override
  State<PublicAuthPage> createState() => _PublicAuthPageState();
}

class _PublicAuthPageState extends State<PublicAuthPage> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final familyName = TextEditingController();
  final slug = TextEditingController();
  bool loading = false;
  String? error;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    familyName.dispose();
    slug.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = marketingCopy[widget.locale]!;
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LoveBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: palette.bgStart.withValues(alpha: .94),
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                onPressed: () =>
                    context.go('/welcome?locale=${widget.locale.code}'),
                icon: const Icon(Icons.arrow_back),
                tooltip: t.back,
              ),
              title: Text(t.brand,
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 610),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 46, 18, 80),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: palette.card.withValues(alpha: .94),
                        border: Border.all(color: palette.border),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: palette.primary.withValues(alpha: .12),
                            blurRadius: 34,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                widget.register ? t.signupTitle : t.loginTitle,
                                style: const TextStyle(
                                  fontSize: 32,
                                  height: 1.08,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.register ? t.signupBody : t.loginBody,
                                style: TextStyle(
                                    color: palette.muted, height: 1.5),
                              ),
                              const SizedBox(height: 26),
                              if (widget.register) ...[
                                TextFormField(
                                  controller: name,
                                  decoration:
                                      InputDecoration(labelText: t.name),
                                  textInputAction: TextInputAction.next,
                                  validator: _required,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: familyName,
                                  decoration:
                                      InputDecoration(labelText: t.familyName),
                                  textInputAction: TextInputAction.next,
                                  validator: _required,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: slug,
                                  decoration: InputDecoration(
                                    labelText: t.slug,
                                    hintText: 'familia-silva',
                                  ),
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 12),
                              ],
                              TextFormField(
                                controller: email,
                                decoration: InputDecoration(labelText: t.email),
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null || !value.contains('@')) {
                                    return t.email;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: password,
                                decoration:
                                    InputDecoration(labelText: t.password),
                                obscureText: true,
                                autofillHints: widget.register
                                    ? const [AutofillHints.newPassword]
                                    : const [AutofillHints.password],
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                validator: (value) {
                                  if (value == null || value.length < 8) {
                                    return t.password;
                                  }
                                  return null;
                                },
                              ),
                              if (error != null) ...[
                                const SizedBox(height: 14),
                                Text(
                                  error!,
                                  style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error),
                                ),
                              ],
                              const SizedBox(height: 24),
                              AppButton(
                                onPressed: loading ? null : _submit,
                                loading: loading,
                                icon: widget.register
                                    ? Icons.favorite_outline
                                    : Icons.login,
                                label:
                                    widget.register ? t.signupButton : t.login,
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: loading
                                    ? null
                                    : () => context.go(
                                          widget.register
                                              ? '/login?locale=${widget.locale.code}'
                                              : '/signup?locale=${widget.locale.code}',
                                        ),
                                child: Text(widget.register
                                    ? t.hasAccount
                                    : t.noAccount),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().length < 2) return 'Campo obrigatório';
    return null;
  }

  Future<void> _submit() async {
    if (loading || formKey.currentState?.validate() != true) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (widget.register) {
        await widget.auth.register(
          email.text.trim(),
          password.text,
          name.text.trim(),
          familyName.text.trim(),
          slug: slug.text.trim(),
          locale: widget.locale.apiCode,
        );
      } else {
        await widget.auth.signIn(email.text.trim(), password.text);
      }
      widget.toast.backendSuccess(widget.auth.takeMessage());
      if (mounted) context.go(widget.register ? '/billing' : '/');
    } catch (reason) {
      final message = authErrorMessage(reason);
      widget.toast.error(message);
      if (mounted) setState(() => error = message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}
