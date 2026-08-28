import 'dart:convert';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import '../site_config.dart';
import '../credentialed_client.dart';

@client
class DemoButton extends StatefulComponent {
  const DemoButton({required this.label, super.key});
  final String label;

  @override
  State<DemoButton> createState() => _DemoButtonState();
}

class _DemoButtonState extends State<DemoButton> {
  bool busy = false;
  String? error;
  String get turnstileId => component.label == 'Experimentar a demo'
      ? 'demo-turnstile-hero'
      : 'demo-turnstile-cta';

  @override
  Component build(BuildContext context) => div(classes: 'demo-action', [
    if (turnstileSiteKey.isNotEmpty)
      div(
        id: turnstileId,
        classes: 'cf-turnstile',
        attributes: const {
          'data-sitekey': turnstileSiteKey,
          'data-action': 'demo',
          'data-theme': 'light',
        },
        [],
      ),
    button(classes: 'button', disabled: busy, onClick: _open, [
      .text(busy ? 'Preparando…' : component.label),
    ]),
    if (error != null)
      small(attributes: const {'role': 'alert'}, [.text(error!)]),
  ]);

  Future<void> _open() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final turnstileToken = _turnstileToken();
      if (turnstileSiteKey.isNotEmpty && turnstileToken == null) {
        throw StateError('Confirme que você não é um robô.');
      }
      final response = await credentialedClient.post(
        Uri.parse('$apiUrl/public/demo-sessions'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'turnstileToken': ?turnstileToken}),
      );
      if (response.statusCode >= 400) {
        final envelope = jsonDecode(response.body) as Map<String, dynamic>;
        throw StateError(
          envelope['message']?.toString() ?? 'Não foi possível abrir a demo.',
        );
      }
      final envelope = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (envelope['data'] ?? envelope) as Map<String, dynamic>;
      final slug = Uri.encodeComponent(data['slug']?.toString() ?? '');
      web.window.location.assign('$appUrl/f/$slug');
    } catch (exception) {
      if (mounted) {
        setState(
          () => error = exception.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String? _turnstileToken() {
    if (!kIsWeb) return null;
    final value =
        (web.document.querySelector(
                  '#$turnstileId [name="cf-turnstile-response"]',
                )
                as web.HTMLInputElement?)
            ?.value
            .trim();
    return value?.isNotEmpty == true ? value : null;
  }
}
