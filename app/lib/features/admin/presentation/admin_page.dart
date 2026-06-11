import 'package:flutter/material.dart';

import '../../../core/api/query_keys.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/query/app_query.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_fixed_header_scroll_view.dart';
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
  List<MiniGameConfig> miniGames = [];
  List<GameStat> stats = [];
  PaginatedResult<AppUser>? usersPagination;
  PaginatedResult<AppNotification>? notificationsPagination;
  PaginatedResult<QuizQuestion>? questionsPagination;
  PaginatedResult<GameWord>? wordsPagination;
  PaginatedResult<MiniGameConfig>? miniGamesPagination;
  PaginatedResult<GameStat>? statsPagination;
  int usersPage = 1;
  int notificationsPage = 1;
  int questionsPage = 1;
  int wordsPage = 1;
  int miniGamesPage = 1;
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
    PaginatedResult<MiniGameConfig>? nextMiniGames;
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
      _fetchPart('mini jogos', () async {
        nextMiniGames = await widget.repository.listMiniGamesAdminPage(
          miniGamesPage,
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
    return _AdminData(
      users: nextUsers,
      notifications: nextNotifications,
      questions: nextQuestions,
      words: nextWords,
      miniGames: nextMiniGames,
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
    return LoveBackground(
      child: AppFixedHeaderScrollView(
        header: const _AdminHero(),
        children: [
          AppQuery<_AdminData>(
            queryKey: QueryKeys.adminPage(
              usersPage: usersPage,
              notificationsPage: notificationsPage,
              questionsPage: questionsPage,
              wordsPage: wordsPage,
              miniGamesPage: miniGamesPage,
              statsPage: statsPage,
            ),
            queryFn: _fetchAdminData,
            loading: _AdminScaffold(
              selected: selected,
              onChanged: (value) => setState(() => selected = value),
              showHero: false,
              child: const _AdminLoadingState(),
            ),
            builder: (context, data, _) {
              _applyAdminData(data);
              return _AdminScaffold(
                selected: selected,
                onChanged: (value) => setState(() => selected = value),
                error: loadError,
                showHero: false,
                child: LovePanel(
                  padding: EdgeInsets.zero,
                  child: SizedBox(
                    height: MediaQuery.sizeOf(context).width >= 860 ? 720 : 640,
                    child: _sectionContent(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _applyAdminData(_AdminData data) {
    usersPagination = data.users;
    notificationsPagination = data.notifications;
    questionsPagination = data.questions;
    wordsPagination = data.words;
    miniGamesPagination = data.miniGames;
    statsPagination = data.stats;
    users = data.users?.items ?? const [];
    notifications = data.notifications?.items ?? const [];
    questions = data.questions?.items ?? const [];
    words = data.words?.items ?? const [];
    miniGames = data.miniGames?.items ?? const [];
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
          miniGames: miniGames,
          loading: false,
          onAddQuestion: () => _openQuestionSheet(),
          onEditQuestion: _openQuestionSheet,
          onDeleteQuestion: _deleteQuestion,
          onAddWord: () => _openWordSheet(),
          onEditWord: _openWordSheet,
          onDeleteWord: _deleteWord,
          onAddMiniGame: () => _openMiniGameSheet(),
          onEditMiniGame: _openMiniGameSheet,
          onDeleteMiniGame: _deleteMiniGame,
          questionsPagination: _pagination(
            questionsPagination,
            (page) => questionsPage = page,
          ),
          wordsPagination: _pagination(
            wordsPagination,
            (page) => wordsPage = page,
          ),
          miniGamesPagination: _pagination(
            miniGamesPagination,
            (page) => miniGamesPage = page,
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
          widget.toast.backendSuccess(widget.repository.takeMessage());
          _invalidateAdmin();
        },
      ),
    );
  }

  Future<void> _deleteUser(AppUser user) async {
    await widget.repository.deleteUser(user.id);
    widget.toast.backendSuccess(widget.repository.takeMessage());
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
          widget.toast.backendSuccess(widget.repository.takeMessage());
          _invalidateAdmin();
        },
      ),
    );
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    await widget.repository.deleteNotification(notification.id);
    widget.toast.backendSuccess(widget.repository.takeMessage());
    _invalidateAdmin();
  }

  Future<void> _clearNotifications() async {
    await widget.repository.clearNotifications();
    notificationsPage = 1;
    widget.toast.backendSuccess(widget.repository.takeMessage());
    _invalidateAdmin();
  }

  Future<void> _sendNotification(AppNotification notification) async {
    await widget.repository.sendNotification(
      title: notification.title,
      body: notification.body,
      url: notification.url,
    );
    widget.toast.backendSuccess(widget.repository.takeMessage());
    _invalidateAdmin();
  }

  Future<void> _scheduleNotification(AppNotification notification) async {
    await showAppSheet<void>(
      context: context,
      builder: (_) => _ScheduleNotificationSheet(
        notification: notification,
        onSchedule: (scheduledAt) async {
          try {
            await widget.repository.scheduleNotification(
              title: notification.title,
              body: notification.body,
              url: notification.url,
              scheduledAt: scheduledAt,
            );
            widget.toast.backendSuccess(widget.repository.takeMessage());
            _invalidateAdmin();
          } catch (error) {
            widget.toast.error(_friendlyError(error));
            rethrow;
          }
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
          widget.toast.backendSuccess(widget.repository.takeMessage());
          _invalidateAdmin();
        },
      ),
    );
  }

  Future<void> _deleteQuestion(QuizQuestion question) async {
    await widget.repository.deleteQuizQuestion(question.id);
    widget.toast.backendSuccess(widget.repository.takeMessage());
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
          widget.toast.backendSuccess(widget.repository.takeMessage());
          _invalidateAdmin();
        },
      ),
    );
  }

  Future<void> _deleteWord(GameWord word) async {
    await widget.repository.deleteGameWord(word.id);
    widget.toast.backendSuccess(widget.repository.takeMessage());
    _invalidateAdmin();
  }

  Future<void> _openMiniGameSheet([MiniGameConfig? miniGame]) async {
    await showAppSheet<void>(
      context: context,
      builder: (_) => _MiniGameSheet(
        miniGame: miniGame,
        onSave: (data) async {
          if (miniGame == null) {
            await widget.repository.createMiniGame(data);
            miniGamesPage = 1;
          } else {
            await widget.repository.updateMiniGame(miniGame.id, data);
          }
          widget.toast.backendSuccess(widget.repository.takeMessage());
          _invalidateAdmin();
        },
      ),
    );
  }

  Future<void> _deleteMiniGame(MiniGameConfig miniGame) async {
    await widget.repository.deleteMiniGame(miniGame.id);
    widget.toast.backendSuccess(widget.repository.takeMessage());
    _invalidateAdmin();
  }
}

const _adminContentPadding = EdgeInsets.fromLTRB(18, 14, 18, 14);
const _adminListPadding = EdgeInsets.fromLTRB(18, 4, 18, 18);

class _AdminData {
  const _AdminData({
    required this.users,
    required this.notifications,
    required this.questions,
    required this.words,
    required this.miniGames,
    required this.stats,
    required this.loadError,
  });

  final PaginatedResult<AppUser>? users;
  final PaginatedResult<AppNotification>? notifications;
  final PaginatedResult<QuizQuestion>? questions;
  final PaginatedResult<GameWord>? words;
  final PaginatedResult<MiniGameConfig>? miniGames;
  final PaginatedResult<GameStat>? stats;
  final String? loadError;
}

enum _AdminSection { users, notifications, games, stats }

class _AdminScaffold extends StatelessWidget {
  const _AdminScaffold({
    required this.selected,
    required this.onChanged,
    required this.child,
    this.error,
    this.showHero = true,
  });

  final _AdminSection selected;
  final ValueChanged<_AdminSection> onChanged;
  final Widget child;
  final String? error;
  final bool showHero;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 860;
        final main = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHero) const _AdminHero(),
            if (error != null) ...[
              if (showHero) const SizedBox(height: 14),
              _AdminErrorBanner(message: error!),
            ],
            if (showHero || error != null) const SizedBox(height: 16),
            if (!wide) ...[
              _AdminSegmentedNav(selected: selected, onChanged: onChanged),
              const SizedBox(height: 12),
            ],
            child,
          ],
        );

        if (!wide) return main;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LovePanel(
              padding: EdgeInsets.zero,
              child: _AdminSideNav(selected: selected, onChanged: onChanged),
            ),
            const SizedBox(width: 18),
            Expanded(child: main),
          ],
        );
      },
    );
  }
}

class _AdminLoadingState extends StatelessWidget {
  const _AdminLoadingState();

  @override
  Widget build(BuildContext context) {
    return LovePanel(
      padding: const EdgeInsets.all(18),
      child: SizedBox(
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            SkeletonBox(width: 220, height: 26),
            SizedBox(height: 18),
            SkeletonBox(height: 78, borderRadius: 8),
            SizedBox(height: 10),
            SkeletonBox(height: 78, borderRadius: 8),
            SizedBox(height: 10),
            SkeletonBox(height: 78, borderRadius: 8),
            SizedBox(height: 10),
            SkeletonBox(height: 78, borderRadius: 8),
          ],
        ),
      ),
    );
  }
}

const _roleOptions = [
  _UserOption('husband', 'Marido', Icons.admin_panel_settings_outlined),
  _UserOption('wife', 'Esposa', Icons.admin_panel_settings_outlined),
  _UserOption('children', 'Filhos', Icons.child_care_outlined),
  _UserOption('friends', 'Amigos', Icons.favorite_outline),
];

const _accessOptions = [
  _UserOption('memorias', 'Memórias em Fotos', Icons.photo_library_outlined),
  _UserOption('playlist', 'Nossa Playlist', Icons.music_note_outlined),
  _UserOption('cartas', 'Cartas de Amor', Icons.card_giftcard_outlined),
  _UserOption('jogos', 'Jogos', Icons.sports_esports_outlined),
  _UserOption('listas', 'Listas', Icons.checklist_outlined),
  _UserOption('localizacao', 'Localização', Icons.location_on_outlined),
  _UserOption('chat', 'Chat', Icons.chat_bubble_outline),
  _UserOption('nossaHistoria', 'Nossa Jornada', Icons.auto_stories_outlined),
];

class _UserOption {
  const _UserOption(this.value, this.label, this.icon);

  final String value;
  final String label;
  final IconData icon;
}

String _roleLabel(String role) {
  return switch (role) {
    'husband' => 'Marido',
    'wife' => 'Esposa',
    'children' => 'Filhos',
    'friends' => 'Amigos',
    _ => role,
  };
}

String _miniGameAdminLabel(String type) {
  return switch (type) {
    'memory_match' => 'Memória da Família',
    'love_order' => 'Linha do Amor',
    'this_or_that' => 'Isso ou Aquilo',
    _ => 'Mini jogo',
  };
}

IconData _miniGameAdminIcon(String type) {
  return switch (type) {
    'memory_match' => Icons.style_outlined,
    'love_order' => Icons.timeline_outlined,
    'this_or_that' => Icons.compare_arrows_outlined,
    _ => Icons.extension_outlined,
  };
}

String _gameStatLabel(String game) {
  return switch (game) {
    'quiz' => 'Quiz do Amor',
    'word_search' => 'Caça Palavras',
    _ => _miniGameAdminLabel(game),
  };
}

IconData _gameStatIcon(String game) {
  return switch (game) {
    'quiz' => Icons.favorite_outline,
    'word_search' => Icons.grid_on_outlined,
    _ => _miniGameAdminIcon(game),
  };
}

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
  'games.mini.created',
  'games.mini.updated',
  'games.mini.deleted',
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
    return SizedBox(
      width: 220,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Text(
              'Seções',
              style: TextStyle(
                color: palette.muted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          for (final section in _AdminSection.values)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: _AdminNavTile(
                section: section,
                selected: selected == section,
                onTap: () => onChanged(section),
              ),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
      padding: _adminContentPadding.copyWith(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            final heading = SizedBox(
              width: double.infinity,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      textAlign: TextAlign.left,
                      style: TextStyle(color: palette.muted, height: 1.25),
                    ),
                  ],
                ),
              ),
            );
            if (action == null) return heading;
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  heading,
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerLeft, child: action!),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: heading),
                const SizedBox(width: 16),
                action!,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AdminSectionBody extends StatelessWidget {
  const _AdminSectionBody({
    required this.loading,
    required this.empty,
    required this.isEmpty,
    required this.itemCount,
    required this.itemBuilder,
  });

  final bool loading;
  final String empty;
  final bool isEmpty;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    if (loading) return const _AdminListSkeleton();
    if (isEmpty) return _EmptyAdminState(empty);
    return ListView.separated(
      padding: _adminListPadding,
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: itemBuilder,
    );
  }
}

class _AdminActions extends StatelessWidget {
  const _AdminActions({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: children,
    );
  }
}

class _AdminSectionTitle extends StatelessWidget {
  const _AdminSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: palette.foreground,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
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
          child: _AdminSectionBody(
            loading: loading,
            isEmpty: users.isEmpty,
            empty: 'Nenhum usuário cadastrado.',
            itemCount: users.length + (pagination == null ? 0 : 1),
            itemBuilder: (context, index) {
              if (index == users.length) return pagination!;
              final user = users[index];
              return _AdminTile(
                icon: Icons.person_outline,
                title: user.name?.isNotEmpty == true ? user.name! : user.email,
                subtitle: '${user.email} • ${_roleLabel(user.role)}',
                onTap: () => onEdit(user),
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
          action: _AdminActions(
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
          child: _AdminSectionBody(
            loading: loading,
            isEmpty: notifications.isEmpty,
            empty: 'Nenhuma notificação cadastrada.',
            itemCount: notifications.length + (pagination == null ? 0 : 1),
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
    required this.miniGames,
    required this.loading,
    required this.onAddQuestion,
    required this.onEditQuestion,
    required this.onDeleteQuestion,
    required this.onAddWord,
    required this.onEditWord,
    required this.onDeleteWord,
    required this.onAddMiniGame,
    required this.onEditMiniGame,
    required this.onDeleteMiniGame,
    required this.questionsPagination,
    required this.wordsPagination,
    required this.miniGamesPagination,
  });

  final List<QuizQuestion> questions;
  final List<GameWord> words;
  final List<MiniGameConfig> miniGames;
  final bool loading;
  final VoidCallback onAddQuestion;
  final ValueChanged<QuizQuestion> onEditQuestion;
  final ValueChanged<QuizQuestion> onDeleteQuestion;
  final VoidCallback onAddWord;
  final ValueChanged<GameWord> onEditWord;
  final ValueChanged<GameWord> onDeleteWord;
  final VoidCallback onAddMiniGame;
  final ValueChanged<MiniGameConfig> onEditMiniGame;
  final ValueChanged<MiniGameConfig> onDeleteMiniGame;
  final Widget? questionsPagination;
  final Widget? wordsPagination;
  final Widget? miniGamesPagination;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AdminToolbar(
          title: 'Jogos',
          subtitle: 'Gerencie perguntas, palavras e mini jogos.',
          action: _AdminActions(
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
              OutlinedButton.icon(
                onPressed: onAddMiniGame,
                icon: const Icon(Icons.add),
                label: const Text('Mini jogo'),
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
                    final miniGameList = _GameSection(
                      title: 'Mini jogos',
                      empty: 'Nenhum mini jogo cadastrado.',
                      scrollable: false,
                      pagination: miniGamesPagination,
                      children: [
                        for (final miniGame in miniGames)
                          _AdminTile(
                            icon: _miniGameAdminIcon(miniGame.type),
                            title: miniGame.title,
                            subtitle:
                                '${_miniGameAdminLabel(miniGame.type)} • ${miniGame.items.length} itens • ${miniGame.active ? 'ativo' : 'inativo'}',
                            actions: [
                              IconButton(
                                onPressed: () => onEditMiniGame(miniGame),
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                onPressed: () => onDeleteMiniGame(miniGame),
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Remover',
                              ),
                            ],
                          ),
                      ],
                    );
                    if (!wide) {
                      return ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          questionList,
                          const SizedBox(height: 18),
                          wordList,
                          const SizedBox(height: 18),
                          miniGameList,
                        ],
                      );
                    }
                    return Column(
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: questionList),
                              const SizedBox(width: 16),
                              Expanded(child: wordList),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        miniGameList,
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
      padding: _adminListPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AdminSectionTitle(title),
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
          child: _AdminSectionBody(
            loading: loading,
            isEmpty: stats.isEmpty,
            empty: 'Nenhuma conclusão registrada.',
            itemCount: stats.length + (pagination == null ? 0 : 1),
            itemBuilder: (context, index) {
              if (index == stats.length) return pagination!;
              final stat = stats[index];
              return _AdminTile(
                icon: _gameStatIcon(stat.game),
                title: stat.playerName,
                subtitle: _gameStatLabel(stat.game),
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
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final actionBar = trailing ?? Wrap(spacing: 4, children: actions);
    final panel = LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620 && actions.length > 2;
        final leading = Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: palette.primary.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: palette.primary),
        );
        final text = Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(subtitle,
                  maxLines: compact ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: palette.muted)),
            ],
          ),
        );

        return LovePanel(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        leading,
                        const SizedBox(width: 14),
                        text,
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: actionBar,
                    ),
                  ],
                )
              : Row(
                  children: [
                    leading,
                    const SizedBox(width: 14),
                    text,
                    const SizedBox(width: 8),
                    actionBar,
                  ],
                ),
        );
      },
    );
    if (onTap == null) return panel;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: panel,
      ),
    );
  }
}

class _AdminListSkeleton extends StatelessWidget {
  const _AdminListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: _adminListPadding,
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const SkeletonBox(height: 76, borderRadius: 8),
    );
  }
}

class _AdminCheckRow extends StatelessWidget {
  const _AdminCheckRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: palette.primary.withValues(alpha: value ? .08 : .03),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(icon, color: value ? palette.primary : palette.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Checkbox(
                  value: value,
                  onChanged: (checked) => onChanged(checked ?? false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminSwitchRow extends StatelessWidget {
  const _AdminSwitchRow({
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Material(
      color: palette.primary.withValues(alpha: .04),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminInfoRow extends StatelessWidget {
  const _AdminInfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Widget title;
  final Widget subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Material(
      color: palette.primary.withValues(alpha: .04),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: palette.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  const SizedBox(height: 4),
                  subtitle,
                ],
              ),
            ),
          ],
        ),
      ),
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
  late Set<String> access;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.user.name ?? '');
    role =
        appUserRoles.contains(widget.user.role) ? widget.user.role : 'friends';
    access = widget.user.access.toSet();
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await widget.onSave({
        'name': name.text,
        'role': role,
        'access': access.toList(),
      });
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in _roleOptions)
                ChoiceChip(
                  avatar: Icon(option.icon, size: 16),
                  label: Text(option.label),
                  selected: role == option.value,
                  onSelected: (_) => setState(() => role = option.value),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Acessos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            role == 'husband' || role == 'wife'
                ? 'Marido e esposa acessam tudo automaticamente.'
                : 'Marque os módulos liberados para esta conta.',
          ),
          const SizedBox(height: 10),
          for (final option in _accessOptions)
            _AdminCheckRow(
              icon: option.icon,
              label: option.label,
              value: access.contains(option.value),
              onChanged: (checked) {
                setState(() {
                  if (checked) {
                    access.add(option.value);
                  } else {
                    access.remove(option.value);
                  }
                });
              },
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
    if (scheduledAt.isBefore(DateTime.now())) return;
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
          _AdminInfoRow(
            icon: Icons.notifications_outlined,
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
            onSave: saving || scheduledAt.isBefore(DateTime.now())
                ? null
                : _schedule,
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
          _AdminSwitchRow(
            value: active,
            onChanged: (value) => setState(() => active = value),
            label: 'Ativa',
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
          _AdminSwitchRow(
            value: active,
            onChanged: (value) => setState(() => active = value),
            label: 'Ativa',
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

class _MiniGameSheet extends StatefulWidget {
  const _MiniGameSheet({required this.onSave, this.miniGame});

  final MiniGameConfig? miniGame;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  @override
  State<_MiniGameSheet> createState() => _MiniGameSheetState();
}

class _MiniGameSheetState extends State<_MiniGameSheet> {
  late String type;
  late final TextEditingController title;
  late final TextEditingController instructions;
  late final TextEditingController items;
  bool active = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final current = widget.miniGame;
    type = current?.type ?? miniGameTypes.first;
    title = TextEditingController(text: current?.title ?? '');
    instructions = TextEditingController(text: current?.instructions ?? '');
    items =
        TextEditingController(text: (current?.items ?? const []).join('\n'));
    active = current?.active ?? true;
  }

  @override
  void dispose() {
    title.dispose();
    instructions.dispose();
    items.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await widget.onSave({
        'type': type,
        'title': title.text,
        'instructions': instructions.text,
        'items': items.text
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList(),
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
      width: 560,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSheetHeader(
            title:
                widget.miniGame == null ? 'Novo mini jogo' : 'Editar mini jogo',
            subtitle:
                'Configure título, instrução e itens. No Isso ou Aquilo use uma rodada por linha: Opção A|Opção B.',
            icon: Icons.extension_outlined,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in miniGameTypes)
                ChoiceChip(
                  selected: type == option,
                  label: Text(_miniGameAdminLabel(option)),
                  onSelected: widget.miniGame == null
                      ? (_) => setState(() => type = option)
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: title,
            decoration: const InputDecoration(labelText: 'Título'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: instructions,
            decoration: const InputDecoration(labelText: 'Instrução'),
            maxLines: 2,
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: items,
            decoration: const InputDecoration(labelText: 'Itens'),
            minLines: 5,
            maxLines: 8,
          ),
          const SizedBox(height: 10),
          _AdminSwitchRow(
            value: active,
            onChanged: (value) => setState(() => active = value),
            label: 'Ativo',
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
