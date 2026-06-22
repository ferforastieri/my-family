import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_fixed_header_scroll_view.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/love_action_card.dart';
import '../../../core/widgets/love_background.dart';

class BillingPage extends StatefulWidget {
  const BillingPage({
    super.key,
    required this.auth,
    required this.toast,
  });

  final AuthController auth;
  final ToastController toast;

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  late final name = TextEditingController(text: widget.auth.tenant?.name);
  late final slug = TextEditingController(text: widget.auth.tenant?.slug);
  String locale = 'pt-BR';
  bool loading = false;

  @override
  void initState() {
    super.initState();
    locale = widget.auth.tenant?.defaultLocale ?? 'pt-BR';
  }

  @override
  void dispose() {
    name.dispose();
    slug.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => loading = true);
    try {
      await action();
      widget.toast.backendSuccess(widget.auth.takeMessage());
    } catch (error) {
      widget.toast.error(authErrorMessage(error));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _checkout() => _run(() async {
        final url = await widget.auth.createCheckout();
        if (url.isEmpty || !await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
          throw StateError('Não foi possível abrir o pagamento.');
        }
      });

  Future<void> _portal() => _run(() async {
        final url = await widget.auth.createBillingPortal();
        if (url.isEmpty || !await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
          throw StateError('Não foi possível abrir o portal da assinatura.');
        }
      });

  Future<void> _refresh() => _run(() async {
        await widget.auth.refreshTenant();
        final tenant = widget.auth.tenant;
        if (tenant != null) {
          name.text = tenant.name;
          slug.text = tenant.slug;
          locale = tenant.defaultLocale;
        }
      });

  Future<void> _save() => _run(() => widget.auth.updateTenant(
        name: name.text,
        slug: slug.text,
        locale: locale,
      ));

  @override
  Widget build(BuildContext context) {
    final tenant = widget.auth.tenant;
    final palette = Theme.of(context).extension<AppPalette>()!;
    return LoveBackground(
      child: AppFixedHeaderScrollView(
        header: const AppPageHeader(
          title: 'Meu espaço',
          subtitle: 'Assinatura, endereço e publicação.',
          icon: Icons.workspace_premium_outlined,
        ),
        children: [
          LovePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: palette.primary.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.favorite, color: palette.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tenant?.name ?? 'Minha família', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      Text(_statusLabel(tenant?.status), style: TextStyle(color: tenant?.isActive == true ? Colors.green.shade700 : palette.primaryDark, fontWeight: FontWeight.w800)),
                    ],
                  )),
                ]),
                const SizedBox(height: 18),
                if (tenant?.isActive != true)
                  AppButton(onPressed: loading ? null : _checkout, loading: loading, label: 'Ativar assinatura', icon: Icons.credit_card)
                else
                  AppButton(onPressed: loading ? null : _portal, loading: loading, label: 'Gerenciar assinatura', icon: Icons.open_in_new),
                const SizedBox(height: 10),
                TextButton.icon(onPressed: loading ? null : _refresh, icon: const Icon(Icons.refresh), label: const Text('Atualizar situação')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LovePanel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Identidade do site', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome exibido')),
              const SizedBox(height: 12),
              TextField(controller: slug, decoration: const InputDecoration(labelText: 'Endereço do site')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: locale,
                decoration: const InputDecoration(labelText: 'Idioma padrão'),
                items: const [
                  DropdownMenuItem(value: 'pt-BR', child: Text('Português')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'es', child: Text('Español')),
                ],
                onChanged: (value) => setState(() => locale = value ?? locale),
              ),
              const SizedBox(height: 16),
              AppButton(onPressed: loading ? null : _save, loading: loading, label: 'Salvar alterações', icon: Icons.save_outlined),
            ]),
          ),
          const SizedBox(height: 16),
          LovePanel(
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Site publicado', style: TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(tenant?.isPublished == true ? 'Seu site está visível para quem possui o link.' : 'Somente você consegue editar e visualizar no painel.'),
              value: tenant?.isPublished == true,
              onChanged: loading || tenant?.isActive != true ? null : (value) => _run(() => widget.auth.setPublished(value)),
            ),
          ),
          if (tenant?.isPublished == true) ...[
            const SizedBox(height: 12),
            AppButton(
              onPressed: () => launchUrl(AppConfig.publicSiteUri(tenant!.slug), mode: LaunchMode.externalApplication),
              label: 'Abrir meu site',
              icon: Icons.public,
            ),
          ],
        ],
      ),
    );
  }
}

String _statusLabel(String? status) => switch (status) {
      'active' => 'Assinatura ativa',
      'past_due' => 'Pagamento pendente',
      'suspended' => 'Assinatura suspensa',
      'canceled' => 'Assinatura cancelada',
      _ => 'Aguardando ativação',
    };

