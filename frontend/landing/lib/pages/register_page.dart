import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import '../components/seo_head.dart';
import '../components/site_shell.dart';
import '../site_config.dart';
import '../credentialed_client.dart';

class RegisterPage extends StatelessComponent {
  const RegisterPage({super.key});

  @override
  Component build(BuildContext context) => SiteShell(
    child: div([
      const SeoHead(
        title: 'Criar minha família — Sião',
        description: 'Crie o espaço privado da sua família com email e senha.',
        path: '/cadastro',
        noIndex: true,
      ),
      if (turnstileSiteKey.isNotEmpty)
        Document.head(
          children: const [
            script(
              src: 'https://challenges.cloudflare.com/turnstile/v0/api.js',
              async: true,
              defer: true,
            ),
          ],
        ),
      section(classes: 'section content', [
        p(classes: 'eyebrow', [.text('Sua casa digital')]),
        h1([.text('Comece pela sua conta.')]),
        p(classes: 'lede', [
          .text(
            'Crie sua conta com email e senha. Em poucos passos o espaço da sua família está pronto.',
          ),
        ]),
        const EmailRegistrationForm(),
      ]),
    ]),
  );
}

@client
class EmailRegistrationForm extends StatefulComponent {
  const EmailRegistrationForm({super.key});

  @override
  State<EmailRegistrationForm> createState() => _EmailRegistrationFormState();
}

class _EmailRegistrationFormState extends State<EmailRegistrationForm> {
  String name = '';
  String email = '';
  String password = '';
  String? invitationToken;
  String? status;
  bool acceptedTerms = false;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      invitationToken = Uri.base.queryParameters['invitation'];
    }
  }

  @override
  Component build(BuildContext context) => form(classes: 'form', [
    _field(
      'Seu nome',
      'text',
      placeholder: 'Como podemos chamar você?',
      autocomplete: 'name',
      onInput: (value) => name = value,
    ),
    _field(
      'Email',
      'email',
      placeholder: 'voce@exemplo.com',
      autocomplete: 'email',
      onInput: (value) => email = value,
    ),
    _field(
      'Senha',
      'password',
      placeholder: 'Mínimo de 8 caracteres',
      autocomplete: 'new-password',
      onInput: (value) => password = value,
    ),
    label([
      span([
        input<bool>(
          type: InputType.checkbox,
          checked: acceptedTerms,
          onChange: (value) => acceptedTerms = value,
        ),
        .text(' Li os '),
        a(href: '/termos', [.text('termos')]),
        .text(' e a '),
        a(href: '/privacidade', [.text('política de privacidade')]),
        .text('.'),
      ]),
    ]),
    if (turnstileSiteKey.isNotEmpty)
      div(
        classes: 'cf-turnstile',
        attributes: const {
          'data-sitekey': turnstileSiteKey,
          'data-action': 'auth',
          'data-theme': 'light',
        },
        [],
      ),
    button(
      type: ButtonType.button,
      classes: 'button primary',
      disabled: busy,
      onClick: _register,
      [.text(busy ? 'Aguarde…' : 'Criar conta')],
    ),
    p(
      attributes: const {'role': 'status', 'aria-live': 'polite'},
      [if (status != null) .text(status!)],
    ),
    p([
      .text('Já tem uma conta? '),
      a(href: appUrl, [.text('Entrar no aplicativo')]),
    ]),
  ]);

  Component _field(
    String labelText,
    String type, {
    String? placeholder,
    String? autocomplete,
    required void Function(String) onInput,
  }) => label([
    .text(labelText),
    input<String>(
      type: switch (type) {
        'email' => InputType.email,
        'password' => InputType.password,
        _ => InputType.text,
      },
      onInput: onInput,
      attributes: {
        'placeholder': ?placeholder,
        'autocomplete': ?autocomplete,
      },
    ),
  ]);

  Future<void> _register() async {
    if (name.trim().isEmpty ||
        !email.contains('@') ||
        password.length < 8 ||
        !acceptedTerms) {
      setState(
        () => status =
            'Preencha nome, email, uma senha com 8+ caracteres e aceite os termos.',
      );
      return;
    }
    await _run(() async {
      final response = await credentialedClient.post(
        Uri.parse('$apiUrl/auth/register'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
          if (invitationToken != null) 'invitationToken': invitationToken,
          if (_turnstileToken() != null) 'turnstileToken': _turnstileToken(),
        }),
      );
      final data = _payload(response);
      if (response.statusCode >= 400) throw StateError(_message(data));
      final tenant = data['tenant'] as Map<String, dynamic>?;
      final tenantSlug = tenant?['slug']?.toString() ?? '';
      final destination = tenantSlug.isEmpty
          ? appUrl
          : '$appUrl/f/${Uri.encodeComponent(tenantSlug)}';
      web.window.location.assign(destination);
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      busy = true;
      status = null;
    });
    try {
      await action();
    } catch (error) {
      setState(() => status = error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Map<String, dynamic> _payload(http.Response response) {
    final envelope = jsonDecode(response.body) as Map<String, dynamic>;
    return (envelope['data'] ?? envelope) as Map<String, dynamic>;
  }

  String _message(Map<String, dynamic> data) =>
      data['message']?.toString() ?? 'Não foi possível continuar.';

  String? _turnstileToken() {
    if (!kIsWeb) return null;
    final input =
        web.document.querySelector('[name="cf-turnstile-response"]')
            as web.HTMLInputElement?;
    final value = input?.value.trim();
    return value?.isNotEmpty == true ? value : null;
  }
}
