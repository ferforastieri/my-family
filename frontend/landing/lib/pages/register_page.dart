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
        title: 'Criar minha família — Nossa Família',
        description: 'Crie o espaço privado da sua família usando seu celular.',
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
        h1([.text('Comece pelo celular.')]),
        p(classes: 'lede', [
          .text(
            'Sem senha e sem formulário longo. Receba um código, confirme o número e entre.',
          ),
        ]),
        const PhoneRegistrationForm(),
      ]),
    ]),
  );
}

@client
class PhoneRegistrationForm extends StatefulComponent {
  const PhoneRegistrationForm({super.key});

  @override
  State<PhoneRegistrationForm> createState() => _PhoneRegistrationFormState();
}

class _PhoneRegistrationFormState extends State<PhoneRegistrationForm> {
  String phone = '';
  String code = '';
  String channel = 'sms';
  String? invitationToken;
  String? status;
  bool acceptedTerms = false;
  bool codeSent = false;
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
    if (!codeSent) ...[
      _field(
        'Celular com DDD',
        'tel',
        placeholder: '(11) 99999-9999',
        onInput: (value) => phone = value,
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
            'data-action': 'phone',
            'data-theme': 'light',
          },
          [],
        ),
    ] else ...[
      p([.text('Enviamos um código de 6 números para $phone.')]),
      _field(
        'Código',
        'text',
        placeholder: '000000',
        maxLength: 6,
        onInput: (value) => code = value,
      ),
    ],
    button(
      type: ButtonType.button,
      classes: 'button primary',
      disabled: busy,
      onClick: codeSent ? _verify : _request,
      [
        .text(
          busy
              ? 'Aguarde…'
              : codeSent
              ? 'Confirmar e entrar'
              : 'Receber código',
        ),
      ],
    ),
    if (codeSent)
      button(
        type: ButtonType.button,
        classes: 'text-button',
        disabled: busy,
        onClick: () => setState(() {
          codeSent = false;
          code = '';
          status = null;
        }),
        [.text('Alterar número')],
      ),
    p(
      attributes: const {'role': 'status', 'aria-live': 'polite'},
      [if (status != null) .text(status!)],
    ),
  ]);

  Component _field(
    String labelText,
    String type, {
    String? placeholder,
    int? maxLength,
    required void Function(String) onInput,
  }) => label([
    .text(labelText),
    input<String>(
      type: type == 'tel' ? InputType.tel : InputType.text,
      onInput: onInput,
      attributes: {
        'placeholder': ?placeholder,
        if (maxLength != null) 'maxlength': '$maxLength',
        'autocomplete': type == 'tel' ? 'tel' : 'on',
      },
    ),
  ]);

  Future<void> _request() async {
    if (phone.trim().isEmpty || !acceptedTerms) {
      setState(() => status = 'Informe o celular e aceite os termos.');
      return;
    }
    await _run(() async {
      final response = await credentialedClient.post(
        Uri.parse('$apiUrl/auth/phone/request-code'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'channel': channel,
          if (_turnstileToken() != null) 'turnstileToken': _turnstileToken(),
        }),
      );
      final data = _payload(response);
      if (response.statusCode >= 400) throw StateError(_message(data));
      setState(() {
        codeSent = true;
        code = data['devCode']?.toString() ?? '';
        status = 'Código enviado. Ele vale por 5 minutos.';
      });
    });
  }

  Future<void> _verify() async {
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => status = 'Digite os 6 números do código.');
      return;
    }
    await _run(() async {
      final response = await credentialedClient.post(
        Uri.parse('$apiUrl/auth/phone/verify-code'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'code': code,
          if (invitationToken != null) 'invitationToken': invitationToken,
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
