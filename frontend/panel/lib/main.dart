import 'dart:convert';

import 'package:family_ui/family_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'credentialed_client.dart';

const apiBase = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3001/api',
);
const familyAppBase = String.fromEnvironment(
  'APP_BASE_URL',
  defaultValue: 'http://localhost:3458',
);

void main() => runApp(const FamilyPanel());

class FamilyPanel extends StatefulWidget {
  const FamilyPanel({super.key});
  @override
  State<FamilyPanel> createState() => _FamilyPanelState();
}

class _FamilyPanelState extends State<FamilyPanel> {
  final session = PanelSession();
  @override
  void initState() {
    super.initState();
    session.restore();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, child) => MaterialApp(
      title: 'Painel — Sião',
      debugShowCheckedModeBanner: false,
      theme: familyTheme(primary: session.primary, font: session.font),
      home: session.loading
          ? const PanelSkeleton()
          : !session.authenticated
          ? LoginPage(session: session)
          : Dashboard(session: session),
    ),
  );
}

class PanelSession extends ChangeNotifier {
  final client = credentialedClient();
  bool loading = true;
  bool authenticated = false;
  String? csrfToken;
  Map<String, dynamic>? user;
  Map<String, dynamic>? tenant;
  List<dynamic> tenants = [];
  Color primary = defaultPrimary;
  FamilyFont font = FamilyFont.nunitoSans;
  String? pendingInvitation = Uri.base.queryParameters['invitation'];

  Future<void> restore() async {
    try {
      final csrf = await request('/auth/csrf', retryAuth: false);
      csrfToken = csrf['csrfToken']?.toString();
      await loadContext();
      authenticated = true;
    } catch (_) {
      authenticated = false;
    }
    loading = false;
    notifyListeners();
  }

  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Object? body,
    bool retryAuth = true,
  }) async {
    var response = await client.send(
      http.Request(method, Uri.parse('$apiBase$path'))
        ..headers.addAll({
          'content-type': 'application/json',
          if (method != 'GET' && csrfToken != null)
            'x-csrf-token': csrfToken!,
        })
        ..body = body == null ? '' : jsonEncode(body),
    );
    var raw = await response.stream.bytesToString();
    if (response.statusCode == 401 && retryAuth && path != '/auth/refresh') {
      final refreshHeaders = <String, String>{
        'content-type': 'application/json',
      };
      if (csrfToken != null) refreshHeaders['x-csrf-token'] = csrfToken!;
      final refreshResponse = await client.post(
        Uri.parse('$apiBase/auth/refresh'),
        headers: refreshHeaders,
        body: '{}',
      );
      if (refreshResponse.statusCode < 400) {
        final envelope = jsonDecode(refreshResponse.body);
        final refreshed = envelope is Map && envelope['data'] != null
            ? envelope['data']
            : envelope;
        csrfToken = (refreshed as Map)['csrfToken']?.toString() ?? csrfToken;
        response = await client.send(
          http.Request(method, Uri.parse('$apiBase$path'))
            ..headers.addAll({
              'content-type': 'application/json',
              if (method != 'GET' && csrfToken != null)
                'x-csrf-token': csrfToken!,
            })
            ..body = body == null ? '' : jsonEncode(body),
        );
        raw = await response.stream.bytesToString();
      }
    }
    final decoded = raw.isEmpty ? <String, dynamic>{} : jsonDecode(raw);
    if (response.statusCode >= 400) {
      final message = decoded is Map ? decoded['message'] : null;
      throw Exception(message ?? 'Falha na solicitação');
    }
    return decoded is Map && decoded.containsKey('data')
        ? decoded['data']
        : decoded;
  }

  Future<void> login(String email, String password) async {
    final data = await request(
      '/auth/login',
      method: 'POST',
      body: {'email': email, 'password': password},
    );
    csrfToken = (data as Map)['csrfToken']?.toString() ?? csrfToken;
    authenticated = true;
    await loadContext();
    notifyListeners();
  }

  Future<void> loadContext() async {
    if (pendingInvitation != null) {
      await request(
        '/invitations/${Uri.encodeComponent(pendingInvitation!)}/accept',
        method: 'POST',
      );
      pendingInvitation = null;
    }
    final me = await request('/auth/me');
    user = me['user'] as Map<String, dynamic>?;
    final choices = await request('/auth/tenants');
    tenants = (choices['items'] as List?) ?? const [];
    tenant = me['tenant'] as Map<String, dynamic>?;
    if (tenant == null && tenants.isNotEmpty) {
      await switchTenant(tenants.first['id'] as String);
      return;
    }
    _applyTheme(tenant?['theme'] as Map<String, dynamic>?);
  }

  Future<void> switchTenant(String tenantId) async {
    final data = await request(
      '/auth/switch-tenant',
      method: 'POST',
      body: {'tenantId': tenantId},
    );
    csrfToken = (data as Map)['csrfToken']?.toString() ?? csrfToken;
    await loadContext();
    notifyListeners();
  }

  void _applyTheme(Map<String, dynamic>? theme) {
    primary =
        parseFamilyColor(theme?['primaryColor'] as String?) ?? defaultPrimary;
    font = familyFontFromApi(theme?['fontFamily'] as String?);
  }

  Future<void> signOut() async {
    try {
      await request(
        '/auth/logout',
        method: 'POST',
        body: const {},
        retryAuth: false,
      );
    } catch (_) {}
    authenticated = false;
    csrfToken = null;
    user = null;
    tenant = null;
    tenants = [];
    notifyListeners();
  }
}

class PanelSkeleton extends StatelessWidget {
  const PanelSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  FamilySkeletonCircle(size: 38),
                  SizedBox(width: 12),
                  FamilySkeletonLine(width: 130, height: 18),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 220,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < 6; i++) ...[
                            const FamilySkeletonLine(height: 38),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FamilySkeletonLine(width: 240, height: 24),
                          const SizedBox(height: 18),
                          Expanded(
                            child: GridView.count(
                              crossAxisCount: 3,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              children: const [
                                FamilySkeletonCard(),
                                FamilySkeletonCard(),
                                FamilySkeletonCard(),
                                FamilySkeletonCard(),
                                FamilySkeletonCard(),
                                FamilySkeletonCard(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PanelListSkeleton extends StatelessWidget {
  const PanelListSkeleton({super.key, this.rows = 3});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows; i++) ...[
          const FamilySkeletonBox(height: 64, borderRadius: 14),
          if (i < rows - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.session});
  final PanelSession session;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  String? error;
  bool busy = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.session.login(email.text.trim(), password.text);
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FamilyCard(
            padding: const EdgeInsets.all(28),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Painel da família',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Entre com seu email e senha.'),
                  const SizedBox(height: 24),
                  FamilyTextField(
                    controller: email,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: 12),
                  FamilyTextField(
                    controller: password,
                    label: 'Senha',
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 16),
                  if (error != null)
                    Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  FamilyButton(
                    label: 'Entrar',
                    loading: busy,
                    expand: true,
                    onPressed: _login,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
  );
}

enum PanelSection { overview, family, members, content, platform }

class Dashboard extends StatefulWidget {
  const Dashboard({super.key, required this.session});
  final PanelSession session;
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  PanelSection selected = PanelSection.overview;
  bool get platformAdmin =>
      widget.session.user?['platformRole'] == 'super_admin';
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Sião'),
      actions: [
        if (widget.session.tenants.length > 1)
          SizedBox(
            width: 220,
            child: FamilySelect<String>(
              value: widget.session.tenant?['id'] as String?,
              hint: 'Escolha a família',
              options: [
                for (final item in widget.session.tenants)
                  FamilySelectOption(
                    value: item['id'] as String,
                    label: item['name'] as String,
                  ),
              ],
              onChanged: (value) {
                if (value != null) widget.session.switchTenant(value);
              },
            ),
          ),
        IconButton(
          tooltip: 'Sair',
          onPressed: widget.session.signOut,
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: Row(
      children: [
        NavigationRail(
          extended: MediaQuery.sizeOf(context).width > 900,
          selectedIndex: PanelSection.values.indexOf(selected),
          onDestinationSelected: (index) =>
              setState(() => selected = PanelSection.values[index]),
          destinations: [
            const NavigationRailDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              label: Text('Visão geral'),
            ),
            const NavigationRailDestination(
              icon: Icon(Icons.home_outlined),
              label: Text('Família'),
            ),
            const NavigationRailDestination(
              icon: Icon(Icons.people_outline),
              label: Text('Membros'),
            ),
            const NavigationRailDestination(
              icon: Icon(Icons.collections_bookmark_outlined),
              label: Text('Conteúdo'),
            ),
            NavigationRailDestination(
              icon: Icon(
                platformAdmin
                    ? Icons.admin_panel_settings_outlined
                    : Icons.lock_outline,
              ),
              label: Text(platformAdmin ? 'Plataforma' : 'Restrito'),
            ),
          ],
        ),
        const VerticalDivider(width: 1),
        Expanded(child: _body()),
      ],
    ),
  );

  Widget _body() => switch (selected) {
    PanelSection.overview => Overview(session: widget.session),
    PanelSection.family => TenantSettings(session: widget.session),
    PanelSection.members => Members(session: widget.session),
    PanelSection.content => ContentAdministration(session: widget.session),
    PanelSection.platform =>
      platformAdmin
          ? PlatformOverview(session: widget.session)
          : const EmptyPanel(
              title: 'Acesso restrito',
              message:
                  'Somente administradores da plataforma podem abrir esta área.',
              icon: Icons.lock_outline,
            ),
  };
}

class PanelPage extends StatelessWidget {
  const PanelPage({
    super.key,
    required this.title,
    required this.child,
    this.description,
  });
  final String title;
  final String? description;
  final Widget child;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(32),
    children: [
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
      if (description != null)
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 24),
          child: Text(description!),
        ),
      child,
    ],
  );
}

class Overview extends StatelessWidget {
  const Overview({super.key, required this.session});
  final PanelSession session;
  @override
  Widget build(BuildContext context) => PanelPage(
    title: 'Olá, ${session.user?['name'] ?? 'família'}',
    description: 'Tudo que precisa de atenção, sem abrir o conteúdo privado.',
    child: Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _Stat('Plano', session.tenant?['planCode'] ?? 'early_access'),
        _Stat('Status', session.tenant?['subscriptionStatus'] ?? 'active'),
        _Stat('Endereço', session.tenant?['slug'] ?? '—'),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final Object value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 230,
    child: FamilyCard(
      padding: const EdgeInsets.all(20),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: 8),
            Text('$value', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
    ),
  );
}

class TenantSettings extends StatelessWidget {
  const TenantSettings({super.key, required this.session});
  final PanelSession session;
  @override
  Widget build(BuildContext context) => PanelPage(
    title: 'Dados da família',
    child: Text(
      'Nome: ${session.tenant?['name'] ?? '—'}\nEndereço: ${session.tenant?['slug'] ?? '—'}',
    ),
  );
}

class Members extends StatefulWidget {
  const Members({super.key, required this.session});
  final PanelSession session;
  @override
  State<Members> createState() => _MembersState();
}

class _MembersState extends State<Members> {
  late Future<List<dynamic>> members;
  late Future<List<dynamic>> invitations;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    members = widget.session
        .request('/tenant/members')
        .then(
          (data) => data is List ? data : (data['items'] as List?) ?? const [],
        );
    invitations = widget.session
        .request('/tenant/invitations')
        .then(
          (data) => data is List ? data : (data['items'] as List?) ?? const [],
        );
  }

  Future<void> _invite() async {
    final email = TextEditingController();
    var role = 'member';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convidar pessoa'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FamilyTextField(
                controller: email,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              FamilySelect<String>(
                value: role,
                label: 'Papel',
                options: const [
                  FamilySelectOption(value: 'member', label: 'Membro'),
                  FamilySelectOption(value: 'admin', label: 'Administrador'),
                ],
                onChanged: (value) =>
                    setDialogState(() => role = value ?? role),
              ),
            ],
          ),
        ),
        actions: [
          FamilyButton(
            variant: FamilyButtonVariant.ghost,
            label: 'Cancelar',
            onPressed: () => Navigator.pop(context, false),
          ),
          FamilyButton(
            label: 'Enviar convite',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (accepted != true || email.text.trim().isEmpty) return;
    final response = await widget.session.request(
      '/tenant/invitations',
      method: 'POST',
      body: {'email': email.text.trim(), 'role': role},
    );
    setState(_reload);
    if (!mounted) return;
    final token = response is Map ? response['token']?.toString() : null;
    if (token == null || token.isEmpty) return;
    final link = '$familyAppBase/?invitation=${Uri.encodeComponent(token)}';
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convite criado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Compartilhe este link com a pessoa convidada:'),
            const SizedBox(height: 12),
            SelectableText(link),
          ],
        ),
        actions: [
          FamilyButton(
            variant: FamilyButtonVariant.ghost,
            label: 'Copiar link',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: link));
              Navigator.pop(context);
            },
          ),
          FamilyButton(
            label: 'Fechar',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PanelPage(
    title: 'Membros e convites',
    description: 'Convide pessoas e escolha o que cada uma pode acessar.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FamilyButton(
            onPressed: _invite,
            icon: Icons.person_add_alt_1,
            label: 'Convidar pessoa',
          ),
        ),
        const SizedBox(height: 20),
        Text('Membros', style: Theme.of(context).textTheme.titleLarge),
        FutureBuilder<List<dynamic>>(
          future: members,
          builder: (_, snapshot) {
            if (snapshot.hasError) return Text('${snapshot.error}');
            if (!snapshot.hasData) return const PanelListSkeleton();
            return Column(
              children: snapshot.data!
                  .map(
                    (item) => ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_outline),
                      ),
                      title: Text(
                        item['name'] ?? item['email'] ?? 'Membro',
                      ),
                      subtitle: Text(item['email'] ?? ''),
                      trailing: Text(item['membershipRole'] ?? 'member'),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 20),
        Text(
          'Convites pendentes',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        FutureBuilder<List<dynamic>>(
          future: invitations,
          builder: (_, snapshot) {
            if (snapshot.hasError) return Text('${snapshot.error}');
            if (!snapshot.hasData) return const PanelListSkeleton();
            if (snapshot.data!.isEmpty) {
              return const Text('Nenhum convite pendente.');
            }
            return Column(
              children: snapshot.data!
                  .map(
                    (item) => ListTile(
                      leading: const Icon(Icons.mail_outlined),
                      title: Text(item['email'] ?? ''),
                      subtitle: Text(
                        item['role'] ?? 'member',
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    ),
  );
}

class PlatformOverview extends StatefulWidget {
  const PlatformOverview({super.key, required this.session});
  final PanelSession session;
  @override
  State<PlatformOverview> createState() => _PlatformOverviewState();
}

class _PlatformOverviewState extends State<PlatformOverview> {
  Future<dynamic>? data;
  @override
  void initState() {
    super.initState();
    data = widget.session.request('/platform/tenants');
  }

  @override
  Widget build(BuildContext context) => PanelPage(
    title: 'Visão da plataforma',
    description: 'Operação e consumo sem acesso ao conteúdo familiar.',
    child: FutureBuilder(
      future: data,
      builder: (_, snapshot) {
        if (snapshot.hasError) return Text('${snapshot.error}');
        if (!snapshot.hasData) return const PanelListSkeleton();
        final items = (snapshot.data?['items'] as List?) ?? const [];
        return Column(
          children: items
              .map(
                (item) => ListTile(
                  title: Text(item['name'] ?? 'Família'),
                  subtitle: Text('${item['slug']} · ${item['status']}'),
                  trailing: Text(item['planCode'] ?? 'early_access'),
                ),
              )
              .toList(),
        );
      },
    ),
  );
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
  });
  final String title, message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class ContentAdministration extends StatelessWidget {
  const ContentAdministration({super.key, required this.session});
  final PanelSession session;

  @override
  Widget build(BuildContext context) => PanelPage(
    title: 'Conteúdo da família',
    description:
        'Abra as ferramentas completas no aplicativo. A sessão permanece protegida pelos cookies seguros da API.',
    child: Align(
      alignment: Alignment.centerLeft,
      child: FamilyButton(
        icon: Icons.open_in_new,
        label: 'Abrir administração de conteúdo',
        onPressed: () async {
          await launchUrl(Uri.parse('$familyAppBase/admin'));
        },
      ),
    ),
  );
}
