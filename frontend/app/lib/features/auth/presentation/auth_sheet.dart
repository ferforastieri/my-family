import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/config/app_config.dart';
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
  final phone = TextEditingController();
  final code = TextEditingController();
  String channel = 'whatsapp';
  bool codeSent = false;
  bool loading = false;
  String? error;

  @override
  void dispose() {
    phone.dispose();
    code.dispose();
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
            title: codeSent ? 'Digite o código' : 'Entrar com celular',
            subtitle: codeSent
                ? 'Enviamos um código de 6 números. Ele vale por 5 minutos.'
                : 'Sem senha: escolha WhatsApp ou SMS e confirme seu número.',
            icon: codeSent
                ? Icons.password_outlined
                : Icons.phone_android_outlined,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: phone,
            enabled: !codeSent,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            decoration: const InputDecoration(
              labelText: 'Celular com DDD',
              hintText: '(11) 99999-9999',
            ),
            textInputAction:
                codeSent ? TextInputAction.next : TextInputAction.done,
            onSubmitted: (_) => codeSent ? null : _requestCode(),
          ),
          if (!codeSent) ...[
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'whatsapp',
                  icon: Icon(Icons.chat_outlined),
                  label: Text('WhatsApp'),
                ),
                ButtonSegment(
                  value: 'sms',
                  icon: Icon(Icons.sms_outlined),
                  label: Text('SMS'),
                ),
              ],
              selected: {channel},
              onSelectionChanged: (value) {
                setState(() => channel = value.first);
              },
            ),
          ] else ...[
            const SizedBox(height: 12),
            TextField(
              controller: code,
              autofocus: true,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'Código'),
              onSubmitted: (_) => _verifyCode(),
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
          AppButton(
            onPressed: codeSent ? _verifyCode : _requestCode,
            loading: loading,
            icon: codeSent ? Icons.login : Icons.send_to_mobile_outlined,
            label: codeSent ? 'Confirmar e entrar' : 'Receber código',
          ),
          if (codeSent)
            TextButton(
              onPressed: loading
                  ? null
                  : () => setState(() {
                        codeSent = false;
                        code.clear();
                        error = null;
                      }),
              child: const Text('Alterar número'),
            ),
          TextButton(
            onPressed: () => launchUrl(
              Uri.parse('${AppConfig.landingUrl}/cadastro'),
              mode: LaunchMode.externalApplication,
            ),
            child: const Text('Criar uma família'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestCode() async {
    await _run(() async {
      final devCode = await widget.auth.requestPhoneCode(phone.text, channel);
      setState(() {
        codeSent = true;
        if (devCode != null) code.text = devCode;
      });
      widget.toast.backendSuccess(widget.auth.takeMessage());
    });
  }

  Future<void> _verifyCode() async {
    await _run(() async {
      await widget.auth.verifyPhoneCode(phone.text, code.text);
      widget.toast.backendSuccess(widget.auth.takeMessage());
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await action();
    } catch (exception) {
      final message = authErrorMessage(exception);
      widget.toast.error(message);
      if (mounted) setState(() => error = message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}
