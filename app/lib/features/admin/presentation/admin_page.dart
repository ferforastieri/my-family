import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/love_background.dart';
import '../../../core/widgets/section_title.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../data/family_repository.dart';
import '../../../data/models.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({
    super.key,
    required this.auth,
    required this.repository,
    required this.toast,
  });

  final AuthController auth;
  final FamilyRepository repository;
  final ToastController toast;

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<AppUser> users = [];
  List<AppNotification> notifications = [];
  List<QuizQuestion> questions = [];
  List<GameWord> words = [];
  List<GameStat> stats = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final results = await Future.wait([
        widget.repository.listUsers(),
        widget.repository.listNotificationsAdmin(),
        widget.repository.listQuizQuestionsAdmin(),
        widget.repository.listGameWordsAdmin(),
        widget.repository.gameStats(),
      ]);
      users = results[0] as List<AppUser>;
      notifications = results[1] as List<AppNotification>;
      questions = results[2] as List<QuizQuestion>;
      words = results[3] as List<GameWord>;
      stats = results[4] as List<GameStat>;
    } catch (error) {
      widget.toast.error(error.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return DefaultTabController(
      length: 4,
      child: LoveBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 28, 18, 44),
          children: [
            const SectionTitle('Administração', size: 38),
            const SizedBox(height: 22),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.card,
                    border: Border.all(color: palette.border),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: palette.primary.withValues(alpha: .08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Material(
                        color: palette.primary.withValues(alpha: .06),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8)),
                        child: const TabBar(
                          isScrollable: true,
                          tabs: [
                            Tab(
                                icon: Icon(Icons.people_outline),
                                text: 'Usuários'),
                            Tab(
                                icon: Icon(Icons.notifications_outlined),
                                text: 'Notificações'),
                            Tab(
                                icon: Icon(Icons.sports_esports_outlined),
                                text: 'Jogos'),
                            Tab(
                                icon: Icon(Icons.query_stats_outlined),
                                text: 'Estatísticas'),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 680,
                        child: TabBarView(
                          children: [
                            _UsersAdminTab(
                              users: users,
                              loading: loading,
                              onEdit: _openUserSheet,
                              onDelete: _deleteUser,
                              onRefresh: _load,
                            ),
                            _NotificationsAdminTab(
                              notifications: notifications,
                              loading: loading,
                              onAdd: () => _openNotificationSheet(),
                              onEdit: _openNotificationSheet,
                              onDelete: _deleteNotification,
                              onClear: _clearNotifications,
                              onSend: _sendNotification,
                              onRefresh: _load,
                            ),
                            _GamesAdminTab(
                              questions: questions,
                              words: words,
                              loading: loading,
                              onAddQuestion: () => _openQuestionSheet(),
                              onEditQuestion: _openQuestionSheet,
                              onDeleteQuestion: _deleteQuestion,
                              onAddWord: () => _openWordSheet(),
                              onEditWord: _openWordSheet,
                              onDeleteWord: _deleteWord,
                              onRefresh: _load,
                            ),
                            _StatsAdminTab(
                                stats: stats,
                                loading: loading,
                                onRefresh: _load),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUserSheet(AppUser user) async {
    await showAppSheet<void>(
      context: context,
      builder: (_) => _UserSheet(
        user: user,
        onSave: (data) async {
          await widget.repository.updateUser(user.id, data);
          widget.toast.success('Usuário atualizado.');
          await _load();
        },
      ),
    );
  }

  Future<void> _deleteUser(AppUser user) async {
    await widget.repository.deleteUser(user.id);
    widget.toast.success('Usuário removido.');
    await _load();
  }

  Future<void> _openNotificationSheet([AppNotification? notification]) async {
    await showAppSheet<void>(
      context: context,
      builder: (_) => _NotificationSheet(
        notification: notification,
        onSave: (data) async {
          if (notification == null) {
            await widget.repository.createNotification(data);
          } else {
            await widget.repository.updateNotification(notification.id, data);
          }
          widget.toast.success('Notificação salva.');
          await _load();
        },
      ),
    );
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    await widget.repository.deleteNotification(notification.id);
    widget.toast.success('Notificação removida.');
    await _load();
  }

  Future<void> _clearNotifications() async {
    await widget.repository.clearNotifications();
    widget.toast.success('Notificações limpas.');
    await _load();
  }

  Future<void> _sendNotification(AppNotification notification) async {
    final sent = await widget.repository.sendNotification(
      title: notification.title,
      body: notification.body,
      url: notification.url,
    );
    widget.toast.success('Notificação enviada para $sent dispositivo(s).');
    await _load();
  }

  Future<void> _openQuestionSheet([QuizQuestion? question]) async {
    await showAppSheet<void>(
      context: context,
      builder: (_) => _QuestionSheet(
        question: question,
        onSave: (data) async {
          if (question == null) {
            await widget.repository.createQuizQuestion(data);
          } else {
            await widget.repository.updateQuizQuestion(question.id, data);
          }
          widget.toast.success('Pergunta salva.');
          await _load();
        },
      ),
    );
  }

  Future<void> _deleteQuestion(QuizQuestion question) async {
    await widget.repository.deleteQuizQuestion(question.id);
    widget.toast.success('Pergunta removida.');
    await _load();
  }

  Future<void> _openWordSheet([GameWord? word]) async {
    await showAppSheet<void>(
      context: context,
      builder: (_) => _WordSheet(
        word: word,
        onSave: (data) async {
          if (word == null) {
            await widget.repository.createGameWord(data);
          } else {
            await widget.repository.updateGameWord(word.id, data);
          }
          widget.toast.success('Palavra salva.');
          await _load();
        },
      ),
    );
  }

  Future<void> _deleteWord(GameWord word) async {
    await widget.repository.deleteGameWord(word.id);
    widget.toast.success('Palavra removida.');
    await _load();
  }
}

class _AdminToolbar extends StatelessWidget {
  const _AdminToolbar({
    required this.title,
    required this.subtitle,
    required this.onRefresh,
    this.action,
  });

  final String title;
  final String subtitle;
  final VoidCallback onRefresh;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: palette.muted)),
              ],
            ),
          ),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class _UsersAdminTab extends StatelessWidget {
  const _UsersAdminTab({
    required this.users,
    required this.loading,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
  });

  final List<AppUser> users;
  final bool loading;
  final ValueChanged<AppUser> onEdit;
  final ValueChanged<AppUser> onDelete;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AdminToolbar(
          title: 'Usuários',
          subtitle: 'Edite perfil, função e remova acessos quando precisar.',
          onRefresh: onRefresh,
        ),
        Expanded(
          child: loading
              ? const _AdminListSkeleton()
              : users.isEmpty
                  ? const _EmptyAdminState('Nenhum usuário cadastrado.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return _AdminTile(
                          icon: Icons.person_outline,
                          title: user.name?.isNotEmpty == true
                              ? user.name!
                              : user.email,
                          subtitle: '${user.email} • ${user.role}',
                          actions: [
                            IconButton(
                              onPressed: () => onEdit(user),
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Editar',
                            ),
                            IconButton(
                              onPressed: () => onDelete(user),
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Remover',
                            ),
                          ],
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _NotificationsAdminTab extends StatelessWidget {
  const _NotificationsAdminTab({
    required this.notifications,
    required this.loading,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onClear,
    required this.onSend,
    required this.onRefresh,
  });

  final List<AppNotification> notifications;
  final bool loading;
  final VoidCallback onAdd;
  final ValueChanged<AppNotification> onEdit;
  final ValueChanged<AppNotification> onDelete;
  final VoidCallback onClear;
  final ValueChanged<AppNotification> onSend;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AdminToolbar(
          title: 'Notificações',
          subtitle: 'Crie, edite, envie push e limpe o histórico.',
          onRefresh: onRefresh,
          action: Wrap(
            spacing: 8,
            children: [
              AppButton(
                onPressed: onAdd,
                label: 'Nova',
                icon: Icons.add,
              ),
              OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.clear_all),
                label: const Text('Limpar'),
              ),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const _AdminListSkeleton()
              : notifications.isEmpty
                  ? const _EmptyAdminState('Nenhuma notificação cadastrada.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _AdminTile(
                          icon: Icons.notifications_outlined,
                          title: notification.title,
                          subtitle:
                              '${notification.body.isEmpty ? 'Sem texto' : notification.body} • ${notification.url}',
                          actions: [
                            IconButton(
                              onPressed: () => onSend(notification),
                              icon: const Icon(Icons.send_outlined),
                              tooltip: 'Enviar push',
                            ),
                            IconButton(
                              onPressed: () => onEdit(notification),
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Editar',
                            ),
                            IconButton(
                              onPressed: () => onDelete(notification),
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Remover',
                            ),
                          ],
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _GamesAdminTab extends StatelessWidget {
  const _GamesAdminTab({
    required this.questions,
    required this.words,
    required this.loading,
    required this.onAddQuestion,
    required this.onEditQuestion,
    required this.onDeleteQuestion,
    required this.onAddWord,
    required this.onEditWord,
    required this.onDeleteWord,
    required this.onRefresh,
  });

  final List<QuizQuestion> questions;
  final List<GameWord> words;
  final bool loading;
  final VoidCallback onAddQuestion;
  final ValueChanged<QuizQuestion> onEditQuestion;
  final ValueChanged<QuizQuestion> onDeleteQuestion;
  final VoidCallback onAddWord;
  final ValueChanged<GameWord> onEditWord;
  final ValueChanged<GameWord> onDeleteWord;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AdminToolbar(
          title: 'Jogos',
          subtitle: 'Gerencie perguntas do Quiz e palavras do Caça Palavras.',
          onRefresh: onRefresh,
          action: Wrap(
            spacing: 8,
            children: [
              AppButton(
                onPressed: onAddQuestion,
                label: 'Pergunta',
                icon: Icons.add,
              ),
              OutlinedButton.icon(
                onPressed: onAddWord,
                icon: const Icon(Icons.add),
                label: const Text('Palavra'),
              ),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const _AdminListSkeleton()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 900;
                    final questionList = _GameSection(
                      title: 'Quiz do Amor',
                      empty: 'Nenhuma pergunta cadastrada.',
                      children: [
                        for (final question in questions)
                          _AdminTile(
                            icon: Icons.favorite_outline,
                            title: question.question,
                            subtitle:
                                '${question.options.length} opções • ${question.active ? 'ativa' : 'inativa'}',
                            actions: [
                              IconButton(
                                onPressed: () => onEditQuestion(question),
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                onPressed: () => onDeleteQuestion(question),
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Remover',
                              ),
                            ],
                          ),
                      ],
                    );
                    final wordList = _GameSection(
                      title: 'Caça Palavras',
                      empty: 'Nenhuma palavra cadastrada.',
                      children: [
                        for (final word in words)
                          _AdminTile(
                            icon: Icons.grid_on_outlined,
                            title: word.word,
                            subtitle: word.active ? 'ativa' : 'inativa',
                            actions: [
                              IconButton(
                                onPressed: () => onEditWord(word),
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                onPressed: () => onDeleteWord(word),
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Remover',
                              ),
                            ],
                          ),
                      ],
                    );
                    if (!wide) {
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
                        children: [
                          questionList,
                          const SizedBox(height: 18),
                          wordList,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: questionList),
                        const SizedBox(width: 16),
                        Expanded(child: wordList),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _GameSection extends StatelessWidget {
  const _GameSection({
    required this.title,
    required this.empty,
    required this.children,
  });

  final String title;
  final String empty;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          if (children.isEmpty)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: palette.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(empty, style: TextStyle(color: palette.muted)),
              ),
            )
          else
            ...children.expand((child) => [child, const SizedBox(height: 10)]),
        ],
      ),
    );
  }
}

class _StatsAdminTab extends StatelessWidget {
  const _StatsAdminTab({
    required this.stats,
    required this.loading,
    required this.onRefresh,
  });

  final List<GameStat> stats;
  final bool loading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AdminToolbar(
          title: 'Estatísticas',
          subtitle: 'Veja quantas vezes cada pessoa concluiu os jogos.',
          onRefresh: onRefresh,
        ),
        Expanded(
          child: loading
              ? const _AdminListSkeleton()
              : stats.isEmpty
                  ? const _EmptyAdminState('Nenhuma conclusão registrada.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
                      itemCount: stats.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final stat = stats[index];
                        return _AdminTile(
                          icon: stat.game == 'quiz'
                              ? Icons.favorite_outline
                              : Icons.grid_on_outlined,
                          title: stat.playerName,
                          subtitle: stat.game == 'quiz'
                              ? 'Quiz do Amor'
                              : 'Caça Palavras',
                          trailing: Text(
                            '${stat.count}x${stat.bestScore == null ? '' : ' • melhor ${stat.bestScore}'}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _AdminTile extends StatelessWidget {
  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actions = const [],
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: .045),
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: palette.primary.withValues(alpha: .14),
          foregroundColor: palette.primary,
          child: Icon(icon),
        ),
        title: Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: trailing ?? Wrap(spacing: 4, children: actions),
      ),
    );
  }
}

class _AdminListSkeleton extends StatelessWidget {
  const _AdminListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const SkeletonBox(height: 76, borderRadius: 8),
    );
  }
}

class _EmptyAdminState extends StatelessWidget {
  const _EmptyAdminState(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Center(
      child: Text(message,
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.muted, fontWeight: FontWeight.w700)),
    );
  }
}

class _UserSheet extends StatefulWidget {
  const _UserSheet({required this.user, required this.onSave});

  final AppUser user;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  @override
  State<_UserSheet> createState() => _UserSheetState();
}

class _UserSheetState extends State<_UserSheet> {
  late final TextEditingController name;
  late String role;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.user.name ?? '');
    role = widget.user.role;
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await widget.onSave({'name': name.text, 'role': role});
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Editar usuário',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          Text(widget.user.email),
          const SizedBox(height: 14),
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Nome'),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                  value: 'friend',
                  icon: Icon(Icons.favorite_outline),
                  label: Text('Pessoa')),
              ButtonSegment(
                  value: 'admin',
                  icon: Icon(Icons.admin_panel_settings_outlined),
                  label: Text('Admin')),
            ],
            selected: {role},
            onSelectionChanged: (value) => setState(() => role = value.first),
          ),
          const SizedBox(height: 18),
          AppButton(
            onPressed: _save,
            label: 'Salvar',
            icon: Icons.check,
            loading: saving,
          ),
        ],
      ),
    );
  }
}

class _NotificationSheet extends StatefulWidget {
  const _NotificationSheet({required this.onSave, this.notification});

  final AppNotification? notification;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  @override
  State<_NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<_NotificationSheet> {
  late final TextEditingController title;
  late final TextEditingController body;
  late final TextEditingController url;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final current = widget.notification;
    title = TextEditingController(text: current?.title ?? '');
    body = TextEditingController(text: current?.body ?? '');
    url = TextEditingController(text: current?.url ?? '/');
  }

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    url.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await widget.onSave({
        'title': title.text,
        'body': body.text,
        'url': url.text.trim().isEmpty ? '/' : url.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 540,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
              widget.notification == null
                  ? 'Nova notificação'
                  : 'Editar notificação',
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          TextField(
            controller: title,
            decoration: const InputDecoration(labelText: 'Título'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: body,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Mensagem'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: url,
            decoration: const InputDecoration(labelText: 'Rota ao abrir'),
          ),
          const SizedBox(height: 18),
          AppButton(
            onPressed: _save,
            label: 'Salvar',
            icon: Icons.check,
            loading: saving,
          ),
        ],
      ),
    );
  }
}

class _QuestionSheet extends StatefulWidget {
  const _QuestionSheet({required this.onSave, this.question});

  final QuizQuestion? question;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  @override
  State<_QuestionSheet> createState() => _QuestionSheetState();
}

class _QuestionSheetState extends State<_QuestionSheet> {
  late final TextEditingController question;
  late final List<TextEditingController> options;
  int correctIndex = 0;
  bool active = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final current = widget.question;
    question = TextEditingController(text: current?.question ?? '');
    options = List.generate(
      4,
      (index) => TextEditingController(
          text: index < (current?.options.length ?? 0)
              ? current!.options[index]
              : ''),
    );
    correctIndex = current?.correctIndex ?? 0;
    active = current?.active ?? true;
  }

  @override
  void dispose() {
    question.dispose();
    for (final option in options) {
      option.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await widget.onSave({
        'question': question.text,
        'options': options.map((option) => option.text).toList(),
        'correctIndex': correctIndex,
        'active': active,
      });
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 540,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.question == null ? 'Nova pergunta' : 'Editar pergunta',
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          TextField(
            controller: question,
            decoration: const InputDecoration(labelText: 'Pergunta'),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  ChoiceChip(
                    selected: correctIndex == i,
                    label: const Text('Correta'),
                    onSelected: (_) => setState(() => correctIndex = i),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: options[i],
                      decoration: InputDecoration(labelText: 'Opção ${i + 1}'),
                    ),
                  ),
                ],
              ),
            ),
          SwitchListTile(
            value: active,
            onChanged: (value) => setState(() => active = value),
            title: const Text('Ativa'),
          ),
          const SizedBox(height: 14),
          AppButton(
            onPressed: _save,
            label: 'Salvar',
            icon: Icons.check,
            loading: saving,
          ),
        ],
      ),
    );
  }
}

class _WordSheet extends StatefulWidget {
  const _WordSheet({required this.onSave, this.word});

  final GameWord? word;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  @override
  State<_WordSheet> createState() => _WordSheetState();
}

class _WordSheetState extends State<_WordSheet> {
  late final TextEditingController word;
  bool active = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    word = TextEditingController(text: widget.word?.word ?? '');
    active = widget.word?.active ?? true;
  }

  @override
  void dispose() {
    word.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await widget.onSave({'word': word.text, 'active': active});
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.word == null ? 'Nova palavra' : 'Editar palavra',
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          TextField(
            controller: word,
            decoration: const InputDecoration(labelText: 'Palavra'),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            value: active,
            onChanged: (value) => setState(() => active = value),
            title: const Text('Ativa'),
          ),
          const SizedBox(height: 14),
          AppButton(
            onPressed: _save,
            label: 'Salvar',
            icon: Icons.check,
            loading: saving,
          ),
        ],
      ),
    );
  }
}
