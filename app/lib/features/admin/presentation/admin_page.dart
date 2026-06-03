import 'package:flutter/material.dart';

import '../../../core/api/query_keys.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/query/app_query.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/app_pagination.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/love_action_card.dart';
import '../../../core/widgets/love_background.dart';
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
  static const _adminPageLimit = 20;

  List<AppUser> users = [];
  List<AppNotification> notifications = [];
  List<QuizQuestion> questions = [];
  List<GameWord> words = [];
  List<GameStat> stats = [];
  PaginatedResult<AppUser>? usersPagination;
  PaginatedResult<AppNotification>? notificationsPagination;
  PaginatedResult<QuizQuestion>? questionsPagination;
  PaginatedResult<GameWord>? wordsPagination;
  PaginatedResult<GameStat>? statsPagination;
  int usersPage = 1;
  int notificationsPage = 1;
  int questionsPage = 1;
  int wordsPage = 1;
  int statsPage = 1;
  String? loadError;
  _AdminSection selected = _AdminSection.users;

  @override
  void initState() {
    super.initState();
    for (final event in _adminRealtimeEvents) {
      widget.repository.socket.on(event, _handleRealtimeChange);
    }
  }

  @override
  void dispose() {
    for (final event in _adminRealtimeEvents) {
      widget.repository.socket.off(event, _handleRealtimeChange);
    }
    super.dispose();
  }

  void _handleRealtimeChange(dynamic _) {
    if (!mounted) return;
    _invalidateAdmin();
  }

  void _invalidateAdmin() {
    if (mounted) invalidateQueries(context, QueryKeys.admin);
  }

  Future<_AdminData> _fetchAdminData() async {
    final errors = <String>[];
    PaginatedResult<AppUser>? nextUsers;
    PaginatedResult<AppNotification>? nextNotifications;
    PaginatedResult<QuizQuestion>? nextQuestions;
    PaginatedResult<GameWord>? nextWords;
    PaginatedResult<GameStat>? nextStats;
    await Future.wait([
      _fetchPart('usuários', () async {
        nextUsers = await widget.repository.listUsersPage(
          usersPage,
          _adminPageLimit,
        );
      }, errors),
      _fetchPart('notificações', () async {
        nextNotifications = await widget.repository.listNotificationsAdminPage(
          notificationsPage,
          _adminPageLimit,
        );
      }, errors),
      _fetchPart('perguntas', () async {
        nextQuestions = await widget.repository.listQuizQuestionsAdminPage(
          questionsPage,
          _adminPageLimit,
        );
      }, errors),
      _fetchPart('palavras', () async {
        nextWords = await widget.repository.listGameWordsAdminPage(
          wordsPage,
          _adminPageLimit,
        );
      }, errors),
      _fetchPart('estatísticas', () async {
        nextStats = await widget.repository.gameStatsPage(
          statsPage,
          _adminPageLimit,
        );
      }, errors),
    ]);
    if (errors.isNotEmpty) {
      widget.toast.error('Algumas áreas não carregaram.');
    }
    return _AdminData(
      users: nextUsers,
      notifications: nextNotifications,
      questions: nextQuestions,
      words: nextWords,
      stats: nextStats,
      loadError: errors.isEmpty ? null : errors.join(' • '),
    );
  }

  Future<void> _fetchPart(
    String label,
    Future<void> Function() loader,
    List<String> errors,
  ) async {
    try {
      await loader();
    } catch (error) {
      errors.add('$label: ${_friendlyError(error)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return LoveBackground(
      child: RefreshIndicator(
        onRefresh: () async => _invalidateAdmin(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 112),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _AdminHero(),
                    const SizedBox(height: 16),
                    AppQuery<_AdminData>(
                      queryKey: QueryKeys.adminPage(
                        usersPage: usersPage,
                        notificationsPage: notificationsPage,
                        questionsPage: questionsPage,
                        wordsPage: wordsPage,
                        statsPage: statsPage,
                      ),
                      queryFn: _fetchAdminData,
                      loading: const PageSkeleton(cards: 4),
                      builder: (context, data, _) {
                        _applyAdminData(data);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _AdminMetrics(
                              users: usersPagination?.total ?? users.length,
                              notifications: notificationsPagination?.total ??
                                  notifications.length,
                              games: (questionsPagination?.total ??
                                      questions.length) +
                                  (wordsPagination?.total ?? words.length),
                              stats: stats.fold<int>(
                                  0, (total, stat) => total + stat.count),
                            ),
                            if (loadError != null) ...[
                              const SizedBox(height: 14),
                              _AdminErrorBanner(message: loadError!),
                            ],
                            const SizedBox(height: 16),
                            LovePanel(
                              padding: EdgeInsets.zero,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final wide = constraints.maxWidth >= 860;
                                  final content = _sectionContent();
                                  if (!wide) {
                                    return Column(
                                      children: [
                                        _AdminSegmentedNav(
                                          selected: selected,
                                          onChanged: (value) =>
                                              setState(() => selected = value),
                                        ),
                                        SizedBox(height: 640, child: content),
                                      ],
                                    );
                                  }
                                  return SizedBox(
                                    height: 720,
                                    child: Row(
                                      children: [
                                        _AdminSideNav(
                                          selected: selected,
                                          onChanged: (value) =>
                                              setState(() => selected = value),
                                        ),
                                        VerticalDivider(
                                            width: 1, color: palette.border),
                                        Expanded(child: content),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyAdminData(_AdminData data) {
    usersPagination = data.users;
    notificationsPagination = data.notifications;
    questionsPagination = data.questions;
    wordsPagination = data.words;
    statsPagination = data.stats;
    users = data.users?.items ?? const [];
    notifications = data.notifications?.items ?? const [];
    questions = data.questions?.items ?? const [];
    words = data.words?.items ?? const [];
    stats = data.stats?.items ?? const [];
    loadError = data.loadError;
  }

  Widget _sectionContent() {
    return switch (selected) {
      _AdminSection.users => _UsersAdminTab(
          users: users,
          loading: false,
          onEdit: _openUserSheet,
          onDelete: _deleteUser,
          pagination: _pagination(
            usersPagination,
            (page) => usersPage = page,
          ),
        ),
      _AdminSection.notifications => _NotificationsAdminTab(
          notifications: notifications,
          loading: false,
          onAdd: () => _openNotificationSheet(),
          onEdit: _openNotificationSheet,
          onDelete: _deleteNotification,
          onClear: _clearNotifications,
          onSend: _sendNotification,
          onSchedule: _scheduleNotification,
          pagination: _pagination(
            notificationsPagination,
            (page) => notificationsPage = page,
          ),
        ),
      _AdminSection.games => _GamesAdminTab(
          questions: questions,
          words: words,
          loading: false,
          onAddQuestion: () => _openQuestionSheet(),
          onEditQuestion: _openQuestionSheet,
          onDeleteQuestion: _deleteQuestion,
          onAddWord: () => _openWordSheet(),
          onEditWord: _openWordSheet,
          onDeleteWord: _deleteWord,
          questionsPagination: _pagination(
            questionsPagination,
            (page) => questionsPage = page,
          ),
          wordsPagination: _pagination(
            wordsPagination,
            (page) => wordsPage = page,
          ),
        ),
      _AdminSection.stats => _StatsAdminTab(
          stats: stats,
          loading: false,
          pagination: _pagination(
            statsPagination,
            (page) => statsPage = page,
          ),
        ),
    };
  }

  Widget? _pagination<T>(
    PaginatedResult<T>? result,
    ValueChanged<int> setPage,
  ) {
    if (result == null || result.pages <= 1) return null;
    return AppPagination(
      page: result.page,
      pages: result.pages,
      total: result.total,
      onPrevious: result.hasPrevious
          ? () {
              setState(() => setPage(result.page - 1));
              _invalidateAdmin();
            }
          : null,
      onNext: result.hasNext
          ? () {
              setState(() => setPage(result.page + 1));
              _invalidateAdmin();
            }
          : null,
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
          _invalidateAdmin();
        },
      ),
    );
  }

  Future<void> _deleteUser(AppUser user) async {
    await widget.repository.deleteUser(user.id);
    widget.toast.success('Usuário removido.');
    _invalidateAdmin();
  }

  Future<void> _openNotificationSheet([AppNotification? notification]) async {
    await showAppSheet<void>(
      context: context,
      builder: (_) => _NotificationSheet(
        notification: notification,
        onSave: (data) async {
          if (notification == null) {
            await widget.repository.createNotification(data);
            notificationsPage = 1;
          } else {
            await widget.repository.updateNotification(notification.id, data);
          }
          widget.toast.success('Notificação salva.');
          _invalidateAdmin();
        },
      ),
    );
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    await widget.repository.deleteNotification(notification.id);
    widget.toast.success('Notificação removida.');
    _invalidateAdmin();
  }

  Future<void> _clearNotifications() async {
    await widget.repository.clearNotifications();
    notificationsPage = 1;
    widget.toast.success('Notificações limpas.');
    _invalidateAdmin();
  }

  Future<void> _sendNotification(AppNotification notification) async {
    await widget.repository.sendNotification(
      title: notification.title,
      body: notification.body,
      url: notification.url,
    );
    widget.toast.success('Notificação enfileirada para envio.');
    _invalidateAdmin();
  }

  Future<void> _scheduleNotification(AppNotification notification) async {
    await showAppSheet<void>(
      context: context,
      builder: (_) => _ScheduleNotificationSheet(
        notification: notification,
        onSchedule: (scheduledAt) async {
          await widget.repository.scheduleNotification(
            title: notification.title,
            body: notification.body,
            url: notification.url,
            scheduledAt: scheduledAt,
          );
          widget.toast.success('Notificação agendada.');
        },
      ),
    );
  }

  Future<void> _openQuestionSheet([QuizQuestion? question]) async {
    await showAppSheet<void>(
      context: context,
      builder: (_) => _QuestionSheet(
        question: question,
        onSave: (data) async {
          if (question == null) {
            await widget.repository.createQuizQuestion(data);
            questionsPage = 1;
          } else {
            await widget.repository.updateQuizQuestion(question.id, data);
          }
          widget.toast.success('Pergunta salva.');
          _invalidateAdmin();
        },
      ),
    );
  }

  Future<void> _deleteQuestion(QuizQuestion question) async {
    await widget.repository.deleteQuizQuestion(question.id);
    widget.toast.success('Pergunta removida.');
    _invalidateAdmin();
  }

  Future<void> _openWordSheet([GameWord? word]) async {
    await showAppSheet<void>(
      context: context,
      builder: (_) => _WordSheet(
        word: word,
        onSave: (data) async {
          if (word == null) {
            await widget.repository.createGameWord(data);
            wordsPage = 1;
          } else {
            await widget.repository.updateGameWord(word.id, data);
          }
          widget.toast.success('Palavra salva.');
          _invalidateAdmin();
        },
      ),
    );
  }

  Future<void> _deleteWord(GameWord word) async {
    await widget.repository.deleteGameWord(word.id);
    widget.toast.success('Palavra removida.');
    _invalidateAdmin();
  }
}

class _AdminData {
  const _AdminData({
    required this.users,
    required this.notifications,
    required this.questions,
    required this.words,
    required this.stats,
    required this.loadError,
  });

  final PaginatedResult<AppUser>? users;
  final PaginatedResult<AppNotification>? notifications;
  final PaginatedResult<QuizQuestion>? questions;
  final PaginatedResult<GameWord>? words;
  final PaginatedResult<GameStat>? stats;
  final String? loadError;
}

enum _AdminSection { users, notifications, games, stats }

const _adminRealtimeEvents = [
  'users.created',
  'users.updated',
  'users.deleted',
  'notifications.created',
  'notifications.updated',
  'notifications.deleted',
  'notifications.cleared',
  'games.quiz.created',
  'games.quiz.updated',
  'games.quiz.deleted',
  'games.words.created',
  'games.words.updated',
  'games.words.deleted',
  'games.stats.changed',
];

extension _AdminSectionView on _AdminSection {
  String get label => switch (this) {
        _AdminSection.users => 'Usuários',
        _AdminSection.notifications => 'Notificações',
        _AdminSection.games => 'Jogos',
        _AdminSection.stats => 'Estatísticas',
      };

  IconData get icon => switch (this) {
        _AdminSection.users => Icons.people_outline,
        _AdminSection.notifications => Icons.notifications_outlined,
        _AdminSection.games => Icons.sports_esports_outlined,
        _AdminSection.stats => Icons.query_stats_outlined,
      };
}

class _AdminHero extends StatelessWidget {
  const _AdminHero();

  @override
  Widget build(BuildContext context) {
    return const AppPageHeader(
      title: 'Administração',
      subtitle: 'Usuários, notificações, jogos e estatísticas.',
      icon: Icons.admin_panel_settings_outlined,
    );
  }
}

class _AdminMetrics extends StatelessWidget {
  const _AdminMetrics({
    required this.users,
    required this.notifications,
    required this.games,
    required this.stats,
  });

  final int users;
  final int notifications;
  final int games;
  final int stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final cards = [
          _MetricData('Usuários', users, Icons.people_outline),
          _MetricData(
              'Notificações', notifications, Icons.notifications_outlined),
          _MetricData('Itens dos jogos', games, Icons.sports_esports_outlined),
          _MetricData('Conclusões', stats, Icons.query_stats_outlined),
        ];
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: wide ? 4 : 2,
          childAspectRatio: wide ? 2.45 : 1.7,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: cards.map((card) => _MetricCard(card)).toList(),
        );
      },
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.icon);
  final String label;
  final int value;
  final IconData icon;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.data);

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return LovePanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: palette.primary.withValues(alpha: .12),
            foregroundColor: palette.primary,
            child: Icon(data.icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${data.value}',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w900)),
                Text(data.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: palette.muted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminErrorBanner extends StatelessWidget {
  const _AdminErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.redAccent.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminSideNav extends StatelessWidget {
  const _AdminSideNav({required this.selected, required this.onChanged});

  final _AdminSection selected;
  final ValueChanged<_AdminSection> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Container(
      width: 236,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          for (final section in _AdminSection.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AdminNavTile(
                section: section,
                selected: selected == section,
                onTap: () => onChanged(section),
              ),
            ),
          const Spacer(),
          Text(
            'Painel privado',
            style: TextStyle(color: palette.muted, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _AdminSegmentedNav extends StatelessWidget {
  const _AdminSegmentedNav({required this.selected, required this.onChanged});

  final _AdminSection selected;
  final ValueChanged<_AdminSection> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: .05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final section in _AdminSection.values)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: selected == section,
                  avatar: Icon(section.icon, size: 16),
                  label: Text(section.label),
                  onSelected: (_) => onChanged(section),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AdminNavTile extends StatelessWidget {
  const _AdminNavTile({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final _AdminSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Material(
      color: selected
          ? palette.primary.withValues(alpha: .12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          child: Row(
            children: [
              Icon(section.icon,
                  color: selected ? palette.primary : palette.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  section.label,
                  style: TextStyle(
                    color: selected ? palette.primary : palette.foreground,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _friendlyError(Object error) {
  final raw = error.toString();
  if (raw.contains('Internal server error')) return 'erro interno';
  if (raw.contains('Autenticação')) return 'sessão expirada';
  if (raw.length > 80) return '${raw.substring(0, 80)}...';
  return raw;
}

class _AdminToolbar extends StatelessWidget {
  const _AdminToolbar({
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
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
    required this.pagination,
  });

  final List<AppUser> users;
  final bool loading;
  final ValueChanged<AppUser> onEdit;
  final ValueChanged<AppUser> onDelete;
  final Widget? pagination;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AdminToolbar(
          title: 'Usuários',
          subtitle: 'Edite perfil, função e remova acessos quando precisar.',
        ),
        Expanded(
          child: loading
              ? const _AdminListSkeleton()
              : users.isEmpty
                  ? const _EmptyAdminState('Nenhum usuário cadastrado.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
                      itemCount: users.length + (pagination == null ? 0 : 1),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index == users.length) return pagination!;
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
    required this.onSchedule,
    required this.pagination,
  });

  final List<AppNotification> notifications;
  final bool loading;
  final VoidCallback onAdd;
  final ValueChanged<AppNotification> onEdit;
  final ValueChanged<AppNotification> onDelete;
  final VoidCallback onClear;
  final ValueChanged<AppNotification> onSend;
  final ValueChanged<AppNotification> onSchedule;
  final Widget? pagination;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AdminToolbar(
          title: 'Notificações',
          subtitle: 'Crie, edite, envie push e limpe o histórico.',
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
                      itemCount:
                          notifications.length + (pagination == null ? 0 : 1),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index == notifications.length) return pagination!;
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
                              onPressed: () => onSchedule(notification),
                              icon: const Icon(Icons.schedule_send_outlined),
                              tooltip: 'Agendar push',
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
    required this.questionsPagination,
    required this.wordsPagination,
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
  final Widget? questionsPagination;
  final Widget? wordsPagination;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AdminToolbar(
          title: 'Jogos',
          subtitle: 'Gerencie perguntas do Quiz e palavras do Caça Palavras.',
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
                      scrollable: wide,
                      pagination: questionsPagination,
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
                      scrollable: wide,
                      pagination: wordsPagination,
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
    required this.scrollable,
    required this.pagination,
    required this.children,
  });

  final String title;
  final String empty;
  final bool scrollable;
  final Widget? pagination;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (scrollable)
            Expanded(
              child: _GameSectionBody(
                empty: empty,
                pagination: pagination,
                children: children,
              ),
            )
          else
            _GameSectionBody(
              empty: empty,
              pagination: pagination,
              children: children,
            ),
        ],
      ),
    );
  }
}

class _GameSectionBody extends StatelessWidget {
  const _GameSectionBody({
    required this.children,
    required this.empty,
    required this.pagination,
  });

  final List<Widget> children;
  final String empty;
  final Widget? pagination;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    if (children.isEmpty) {
      return LovePanel(
        padding: const EdgeInsets.all(18),
        child: Text(empty, style: TextStyle(color: palette.muted)),
      );
    }
    final list = ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: children.length + (pagination == null ? 0 : 1),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == children.length) return pagination!;
        return children[index];
      },
    );
    return list;
  }
}

class _StatsAdminTab extends StatelessWidget {
  const _StatsAdminTab({
    required this.stats,
    required this.loading,
    required this.pagination,
  });

  final List<GameStat> stats;
  final bool loading;
  final Widget? pagination;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AdminToolbar(
          title: 'Estatísticas',
          subtitle: 'Veja quantas vezes cada pessoa concluiu os jogos.',
        ),
        Expanded(
          child: loading
              ? const _AdminListSkeleton()
              : stats.isEmpty
                  ? const _EmptyAdminState('Nenhuma conclusão registrada.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
                      itemCount: stats.length + (pagination == null ? 0 : 1),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index == stats.length) return pagination!;
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
    return LovePanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: palette.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: palette.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing ?? Wrap(spacing: 4, children: actions),
        ],
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
          const AppSheetHeader(
            title: 'Editar usuário',
            subtitle: 'Ajuste o nome e o nível de acesso desta conta.',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 14),
          Text(widget.user.email),
          const SizedBox(height: 14),
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Nome'),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
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
          AppSheetActions(
            onCancel: saving ? null : () => Navigator.pop(context),
            onSave: saving ? null : _save,
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
          AppSheetHeader(
            title: widget.notification == null
                ? 'Nova notificação'
                : 'Editar notificação',
            subtitle: 'Defina a mensagem que será enviada para a família.',
            icon: Icons.notifications_active_outlined,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: title,
            decoration: const InputDecoration(labelText: 'Título'),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: body,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Mensagem'),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: url,
            decoration: const InputDecoration(labelText: 'Rota ao abrir'),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 18),
          AppSheetActions(
            onCancel: saving ? null : () => Navigator.pop(context),
            onSave: saving ? null : _save,
            loading: saving,
          ),
        ],
      ),
    );
  }
}

class _ScheduleNotificationSheet extends StatefulWidget {
  const _ScheduleNotificationSheet({
    required this.notification,
    required this.onSchedule,
  });

  final AppNotification notification;
  final Future<void> Function(DateTime scheduledAt) onSchedule;

  @override
  State<_ScheduleNotificationSheet> createState() =>
      _ScheduleNotificationSheetState();
}

class _ScheduleNotificationSheetState
    extends State<_ScheduleNotificationSheet> {
  DateTime selectedDate = DateTime.now().add(const Duration(minutes: 10));
  TimeOfDay selectedTime =
      TimeOfDay.fromDateTime(DateTime.now().add(const Duration(minutes: 10)));
  bool saving = false;

  DateTime get scheduledAt => DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.isBefore(now) ? now : selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  Future<void> _schedule() async {
    if (scheduledAt.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha uma data futura.')),
      );
      return;
    }
    setState(() => saving = true);
    try {
      await widget.onSchedule(scheduledAt);
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
          const AppSheetHeader(
            title: 'Agendar notificação',
            subtitle: 'Escolha quando a família deve receber o push.',
            icon: Icons.schedule_send_outlined,
          ),
          const SizedBox(height: 14),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notifications_outlined),
            title: Text(widget.notification.title,
                style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text(widget.notification.body.isEmpty
                ? 'Sem mensagem'
                : widget.notification.body),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: saving ? null : _pickDate,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                      '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: saving ? null : _pickTime,
                  icon: const Icon(Icons.schedule_outlined),
                  label: Text(selectedTime.format(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AppSheetActions(
            onCancel: saving ? null : () => Navigator.pop(context),
            onSave: saving ? null : _schedule,
            loading: saving,
            saveLabel: 'Agendar',
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
          AppSheetHeader(
            title:
                widget.question == null ? 'Nova pergunta' : 'Editar pergunta',
            subtitle: 'Monte as opções e marque qual resposta está correta.',
            icon: Icons.quiz_outlined,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: question,
            decoration: const InputDecoration(labelText: 'Pergunta'),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
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
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _save(),
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
          AppSheetActions(
            onCancel: saving ? null : () => Navigator.pop(context),
            onSave: saving ? null : _save,
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
          AppSheetHeader(
            title: widget.word == null ? 'Nova palavra' : 'Editar palavra',
            subtitle: 'Cadastre palavras que aparecem no caça-palavras.',
            icon: Icons.extension_outlined,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: word,
            decoration: const InputDecoration(labelText: 'Palavra'),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            value: active,
            onChanged: (value) => setState(() => active = value),
            title: const Text('Ativa'),
          ),
          const SizedBox(height: 14),
          AppSheetActions(
            onCancel: saving ? null : () => Navigator.pop(context),
            onSave: saving ? null : _save,
            loading: saving,
          ),
        ],
      ),
    );
  }
}
