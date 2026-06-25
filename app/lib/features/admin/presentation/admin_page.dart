import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/query_keys.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/config/app_config.dart';
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
  final scaffoldKey = GlobalKey<ScaffoldState>();

  List<AppUser> users = [];
  List<AppNotification> notifications = [];
  List<ScheduledNotification> scheduledNotifications = [];
  List<QuizQuestion> questions = [];
  List<GameWord> words = [];
  List<MiniGameConfig> miniGames = [];
  List<GameStat> stats = [];
  List<HomeEventConfig> homeEvents = [];
  List<String> homeGalleryImages = [];
  int? homeGalleryOrder;
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
    List<ScheduledNotification>? nextScheduledNotifications;
    PaginatedResult<QuizQuestion>? nextQuestions;
    PaginatedResult<GameWord>? nextWords;
    PaginatedResult<MiniGameConfig>? nextMiniGames;
    PaginatedResult<GameStat>? nextStats;
    HomeSettingsConfig? nextHomeSettings;
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
      _fetchPart('agendadas', () async {
        nextScheduledNotifications =
            await widget.repository.listScheduledNotifications();
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
      _fetchPart('datas da Home', () async {
        nextHomeSettings = await widget.repository.getHomeSettings();
      }, errors),
    ]);
    return _AdminData(
      users: nextUsers,
      notifications: nextNotifications,
      scheduledNotifications: nextScheduledNotifications,
      questions: nextQuestions,
      words: nextWords,
      miniGames: nextMiniGames,
      stats: nextStats,
      homeSettings: nextHomeSettings,
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
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.transparent,
      endDrawer: Drawer(
        width: 320,
        child: _AdminRightNavigation(
          selected: selected,
          onChanged: _selectSection,
        ),
      ),
      body: LoveBackground(
        child: AppFixedHeaderScrollView(
          header: AppPageHeader(
            title: 'Administração da família',
            subtitle: selected.label,
            icon: Icons.admin_panel_settings_outlined,
            actionLabel: 'Menu',
            actionIcon: Icons.menu_open_outlined,
            inlineAction: true,
            onAction: () => scaffoldKey.currentState?.openEndDrawer(),
          ),
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
                child: const _AdminLoadingState(),
              ),
              builder: (context, data, _) {
                _applyAdminData(data);
                return _AdminScaffold(
                  error: loadError,
                  child: SizedBox(
                    height: MediaQuery.sizeOf(context).width >= 860 ? 720 : 640,
                    child: _sectionContent(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _selectSection(_AdminSection value) {
    setState(() => selected = value);
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
    scheduledNotifications = data.scheduledNotifications ?? const [];
    questions = data.questions?.items ?? const [];
    words = data.words?.items ?? const [];
    miniGames = data.miniGames?.items ?? const [];
    stats = data.stats?.items ?? const [];
    homeEvents = data.homeSettings?.events ?? const [];
    homeGalleryImages = data.homeSettings?.galleryImages ?? const [];
    homeGalleryOrder = data.homeSettings?.galleryOrder;
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
          scheduledNotifications: scheduledNotifications,
          loading: false,
          onAdd: () => _openNotificationSheet(),
          onEdit: _openNotificationSheet,
          onDelete: _deleteNotification,
          onSend: _sendNotification,
          onScheduleNew: () => _scheduleNotification(),
          onDeleteScheduled: _deleteScheduledNotification,
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
      _AdminSection.home => _HomeSettingsAdminTab(
          events: homeEvents,
          galleryImages: homeGalleryImages,
          galleryOrder: homeGalleryOrder,
          repository: widget.repository,
          onSave: (settings) async {
            await widget.repository.updateHomeSettings(settings);
            widget.toast.backendSuccess(widget.repository.takeMessage());
            _invalidateAdmin();
          },
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

  Future<void> _sendNotification(AppNotification notification) async {
    await widget.repository.sendNotification(
      title: notification.title,
      body: notification.body,
      url: notification.url,
    );
    widget.toast.backendSuccess(widget.repository.takeMessage());
    _invalidateAdmin();
  }

  Future<void> _deleteScheduledNotification(
    ScheduledNotification notification,
  ) async {
    await widget.repository.deleteScheduledNotification(notification.id);
    widget.toast.backendSuccess(widget.repository.takeMessage());
    _invalidateAdmin();
  }

  Future<void> _scheduleNotification([AppNotification? notification]) async {
    await showAppSheet<void>(
      context: context,
      builder: (_) => _ScheduleNotificationSheet(
        notification: notification,
        onSchedule: ({
          required String title,
          String? body,
          String? url,
          required DateTime scheduledAt,
        }) async {
          try {
            await widget.repository.scheduleNotification(
              title: title,
              body: body,
              url: url,
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
    required this.scheduledNotifications,
    required this.questions,
    required this.words,
    required this.miniGames,
    required this.stats,
    required this.homeSettings,
    required this.loadError,
  });

  final PaginatedResult<AppUser>? users;
  final PaginatedResult<AppNotification>? notifications;
  final List<ScheduledNotification>? scheduledNotifications;
  final PaginatedResult<QuizQuestion>? questions;
  final PaginatedResult<GameWord>? words;
  final PaginatedResult<MiniGameConfig>? miniGames;
  final PaginatedResult<GameStat>? stats;
  final HomeSettingsConfig? homeSettings;
  final String? loadError;
}

enum _AdminSection { users, notifications, games, stats, home }

class _AdminScaffold extends StatelessWidget {
  const _AdminScaffold({
    required this.child,
    this.error,
  });

  final Widget child;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return LovePanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _AdminErrorBanner(message: error!),
            ),
          child,
        ],
      ),
    );
  }
}

class _AdminRightNavigation extends StatelessWidget {
  const _AdminRightNavigation({
    required this.selected,
    required this.onChanged,
  });

  final _AdminSection selected;
  final ValueChanged<_AdminSection> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Menu administrativo',
                    style: TextStyle(
                      color: palette.foreground,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.close),
                  tooltip: 'Fechar',
                ),
              ],
            ),
            Text(
              'Escolha uma área para gerenciar.',
              style: TextStyle(
                color: palette.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            for (final section in _AdminSection.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AdminNavTile(
                  section: section,
                  selected: selected == section,
                  onTap: () {
                    onChanged(section);
                    Navigator.maybePop(context);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AdminLoadingState extends StatelessWidget {
  const _AdminLoadingState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 520,
      child: Padding(
        padding: const EdgeInsets.all(18),
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
  _UserOption('owner', 'Proprietário', Icons.workspace_premium_outlined),
  _UserOption('admin', 'Administrador', Icons.admin_panel_settings_outlined),
  _UserOption('member', 'Membro', Icons.favorite_outline),
];

const _accessOptions = [
  _UserOption('memorias', 'Memórias em Fotos', Icons.photo_library_outlined),
  _UserOption('playlist', 'Nossa Playlist', Icons.music_note_outlined),
  _UserOption('cartas', 'Cartas de Amor', Icons.card_giftcard_outlined),
  _UserOption('jogos', 'Jogos', Icons.sports_esports_outlined),
  _UserOption('listas', 'Listas', Icons.checklist_outlined),
  _UserOption('notas', 'Notas', Icons.sticky_note_2_outlined),
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
    'owner' => 'Proprietário',
    'admin' => 'Administrador',
    'member' => 'Membro',
    _ => role,
  };
}

String _correctAnswerLabel(QuizQuestion question) {
  final index = question.correctIndex;
  if (index == null || question.options.isEmpty) return '-';
  final safeIndex = index.clamp(0, question.options.length - 1).toInt();
  return question.options[safeIndex];
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
  'notifications.scheduled.changed',
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
  'home.settings.changed',
];

extension _AdminSectionView on _AdminSection {
  String get label => switch (this) {
        _AdminSection.users => 'Usuários',
        _AdminSection.notifications => 'Notificações',
        _AdminSection.games => 'Jogos',
        _AdminSection.stats => 'Estatísticas',
        _AdminSection.home => 'Home',
      };

  IconData get icon => switch (this) {
        _AdminSection.users => Icons.people_outline,
        _AdminSection.notifications => Icons.notifications_outlined,
        _AdminSection.games => Icons.sports_esports_outlined,
        _AdminSection.stats => Icons.query_stats_outlined,
        _AdminSection.home => Icons.home_outlined,
      };
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(section.icon,
                  color: selected ? palette.primary : palette.muted),
              const SizedBox(width: 10),
              Text(
                section.label,
                style: TextStyle(
                  color: selected ? palette.primary : palette.foreground,
                  fontWeight: FontWeight.w900,
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
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(width: double.infinity, child: action!),
                  ),
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
  const _AdminActions({
    required this.children,
    this.fullWidthOnCompact = false,
  });

  final List<Widget> children;
  final bool fullWidthOnCompact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        if (compact && fullWidthOnCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                SizedBox(width: double.infinity, child: children[index]),
                if (index != children.length - 1) const SizedBox(height: 8),
              ],
            ],
          );
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: compact ? WrapAlignment.start : WrapAlignment.end,
          children: [
            for (final child in children)
              if (compact)
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 132),
                  child: child,
                )
              else
                child,
          ],
        );
      },
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
    required this.scheduledNotifications,
    required this.loading,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onSend,
    required this.onScheduleNew,
    required this.onDeleteScheduled,
    required this.pagination,
  });

  final List<AppNotification> notifications;
  final List<ScheduledNotification> scheduledNotifications;
  final bool loading;
  final VoidCallback onAdd;
  final ValueChanged<AppNotification> onEdit;
  final ValueChanged<AppNotification> onDelete;
  final ValueChanged<AppNotification> onSend;
  final VoidCallback onScheduleNew;
  final ValueChanged<ScheduledNotification> onDeleteScheduled;
  final Widget? pagination;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      if (scheduledNotifications.isNotEmpty) ...[
        const _AdminSectionTitle('Agendadas'),
        for (final scheduled in scheduledNotifications)
          _AdminTile(
            icon: Icons.schedule_send_outlined,
            title: scheduled.title,
            subtitle:
                '${scheduled.body.isEmpty ? 'Sem texto' : scheduled.body} • ${_scheduledStatusLabel(scheduled.status)} • ${_formatAdminDateTime(scheduled.scheduledAt)}',
            trailing: _StatusPill(
              label: _scheduledStatusLabel(scheduled.status),
              tone: scheduled.status,
              onDelete: () => onDeleteScheduled(scheduled),
            ),
          ),
        const SizedBox(height: 8),
      ],
      if (notifications.isNotEmpty) ...[
        const _AdminSectionTitle('Cadastradas'),
        for (final notification in notifications)
          _AdminTile(
            icon: Icons.notifications_outlined,
            title: notification.title,
            subtitle:
                '${notification.body.isEmpty ? 'Sem texto' : notification.body} • ${notification.url}',
            trailing: Wrap(
              spacing: 2,
              children: [
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
            ),
          ),
        if (pagination != null) pagination!,
      ],
    ];
    return Column(
      children: [
        _AdminToolbar(
          title: 'Notificações',
          subtitle: 'Crie, edite, envie push e acompanhe agendamentos.',
          action: _AdminActions(
            fullWidthOnCompact: true,
            children: [
              AppButton(
                onPressed: onAdd,
                label: 'Nova',
                icon: Icons.add,
              ),
              AppButton(
                onPressed: onScheduleNew,
                label: 'Agendar',
                icon: Icons.schedule_send_outlined,
              ),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const _AdminListSkeleton()
              : items.isEmpty
                  ? const _EmptyAdminState('Nenhuma notificação cadastrada.')
                  : ListView.separated(
                      padding: _adminListPadding,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) => items[index],
                    ),
        ),
      ],
    );
  }
}

enum _GamesAdminSection { quiz, words, memoryMatch, loveOrder, thisOrThat }

class _GamesAdminTab extends StatefulWidget {
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
  State<_GamesAdminTab> createState() => _GamesAdminTabState();
}

class _GamesAdminTabState extends State<_GamesAdminTab> {
  _GamesAdminSection section = _GamesAdminSection.quiz;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AdminToolbar(
          title: 'Jogos',
          subtitle: 'Configure cada jogo separadamente.',
          action: _AdminActions(
            fullWidthOnCompact: true,
            children: [
              if (section == _GamesAdminSection.quiz)
                AppButton(
                  onPressed: widget.onAddQuestion,
                  label: 'Pergunta',
                  icon: Icons.add,
                ),
              if (section == _GamesAdminSection.words)
                AppButton(
                  onPressed: widget.onAddWord,
                  label: 'Palavra',
                  icon: Icons.add,
                ),
            ],
          ),
        ),
        Padding(
          padding: _adminContentPadding.copyWith(top: 0, bottom: 12),
          child: _GameAdminNav(
            selected: section,
            onChanged: (value) => setState(() => section = value),
          ),
        ),
        Expanded(
          child: widget.loading
              ? const _AdminListSkeleton()
              : switch (section) {
                  _GamesAdminSection.quiz => _GameSection(
                      title: 'Quiz do Amor',
                      empty: 'Nenhuma pergunta cadastrada.',
                      scrollable: true,
                      pagination: widget.questionsPagination,
                      children: [
                        for (final question in widget.questions)
                          _AdminTile(
                            icon: Icons.favorite_outline,
                            title: question.question,
                            subtitle:
                                '${question.options.length} opções • correta: ${_correctAnswerLabel(question)} • ${question.active ? 'ativa' : 'inativa'}',
                            actions: [
                              IconButton(
                                onPressed: () =>
                                    widget.onEditQuestion(question),
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                onPressed: () =>
                                    widget.onDeleteQuestion(question),
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Remover',
                              ),
                            ],
                          ),
                      ],
                    ),
                  _GamesAdminSection.words => _GameSection(
                      title: 'Caça Palavras',
                      empty: 'Nenhuma palavra cadastrada.',
                      scrollable: true,
                      pagination: widget.wordsPagination,
                      children: [
                        for (final word in widget.words)
                          _AdminTile(
                            icon: Icons.grid_on_outlined,
                            title: word.word,
                            subtitle:
                                '${word.word.length} letras • ${word.active ? 'ativa' : 'inativa'}',
                            actions: [
                              IconButton(
                                onPressed: () => widget.onEditWord(word),
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                onPressed: () => widget.onDeleteWord(word),
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Remover',
                              ),
                            ],
                          ),
                      ],
                    ),
                  _GamesAdminSection.memoryMatch => _MiniGameConfigSection(
                      title: 'Memória da Família',
                      empty: 'Nenhuma configuração de memória cadastrada.',
                      games: _configsByType('memory_match'),
                      onEdit: widget.onEditMiniGame,
                      onDelete: widget.onDeleteMiniGame,
                    ),
                  _GamesAdminSection.loveOrder => _MiniGameConfigSection(
                      title: 'Linha do Amor',
                      empty: 'Nenhuma configuração de linha cadastrada.',
                      games: _configsByType('love_order'),
                      onEdit: widget.onEditMiniGame,
                      onDelete: widget.onDeleteMiniGame,
                    ),
                  _GamesAdminSection.thisOrThat => _MiniGameConfigSection(
                      title: 'Isso ou Aquilo',
                      empty: 'Nenhuma configuração de escolhas cadastrada.',
                      games: _configsByType('this_or_that'),
                      onEdit: widget.onEditMiniGame,
                      onDelete: widget.onDeleteMiniGame,
                    ),
                },
        ),
      ],
    );
  }

  List<MiniGameConfig> _configsByType(String type) {
    return widget.miniGames.where((game) => game.type == type).toList();
  }
}

class _MiniGameConfigSection extends StatelessWidget {
  const _MiniGameConfigSection({
    required this.title,
    required this.empty,
    required this.games,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String empty;
  final List<MiniGameConfig> games;
  final ValueChanged<MiniGameConfig> onEdit;
  final ValueChanged<MiniGameConfig> onDelete;

  @override
  Widget build(BuildContext context) {
    return _GameSection(
      title: title,
      empty: empty,
      scrollable: true,
      pagination: null,
      children: [
        for (final miniGame in games)
          _AdminTile(
            icon: _miniGameAdminIcon(miniGame.type),
            title: miniGame.title,
            subtitle:
                '${_miniGameAdminLabel(miniGame.type)} • ${miniGame.items.length} itens • ${miniGame.active ? 'ativo' : 'inativo'}',
            actions: [
              IconButton(
                onPressed: () => onEdit(miniGame),
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar',
              ),
              IconButton(
                onPressed: () => onDelete(miniGame),
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Remover',
              ),
            ],
          ),
      ],
    );
  }
}

class _GameAdminNav extends StatelessWidget {
  const _GameAdminNav({required this.selected, required this.onChanged});

  final _GamesAdminSection selected;
  final ValueChanged<_GamesAdminSection> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<_GamesAdminSection>(
        segments: const [
          ButtonSegment(
            value: _GamesAdminSection.quiz,
            icon: Icon(Icons.quiz_outlined),
            label: Text('Quiz do Amor'),
          ),
          ButtonSegment(
            value: _GamesAdminSection.words,
            icon: Icon(Icons.grid_on_outlined),
            label: Text('Caça Palavras'),
          ),
          ButtonSegment(
            value: _GamesAdminSection.memoryMatch,
            icon: Icon(Icons.style_outlined),
            label: Text('Memória da Família'),
          ),
          ButtonSegment(
            value: _GamesAdminSection.loveOrder,
            icon: Icon(Icons.timeline_outlined),
            label: Text('Linha do Amor'),
          ),
          ButtonSegment(
            value: _GamesAdminSection.thisOrThat,
            icon: Icon(Icons.compare_arrows_outlined),
            label: Text('Isso ou Aquilo'),
          ),
        ],
        selected: {selected},
        onSelectionChanged: (values) => onChanged(values.first),
      ),
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

class _HomeSettingsAdminTab extends StatelessWidget {
  const _HomeSettingsAdminTab({
    required this.events,
    required this.galleryImages,
    required this.galleryOrder,
    required this.repository,
    required this.onSave,
  });

  final List<HomeEventConfig> events;
  final List<String> galleryImages;
  final int? galleryOrder;
  final FamilyRepository repository;
  final Future<void> Function(HomeSettingsConfig settings) onSave;

  int get _normalizedGalleryOrder =>
      (galleryOrder ?? events.length).clamp(0, events.length);

  @override
  Widget build(BuildContext context) {
    final items = _homeAdminItems();
    return Column(
      children: [
        _AdminToolbar(
          title: 'Home',
          subtitle: 'Cards, visibilidade e carrossel de fotos da tela inicial.',
          action: AppButton(
            onPressed: () => _openEventSheet(context),
            label: 'Criar',
            icon: Icons.add,
          ),
        ),
        Expanded(
          child: _AdminSectionBody(
            loading: false,
            isEmpty: events.isEmpty && galleryImages.isEmpty,
            empty: 'A Home ainda não foi carregada.',
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              if (item.isGallery) {
                return _AdminTile(
                  icon: Icons.auto_awesome_motion_outlined,
                  title: 'Carrossel de fotos',
                  subtitle:
                      '${galleryImages.length} foto${galleryImages.length == 1 ? '' : 's'} • aparece como card flutuante na Home',
                  actions: [
                    IconButton(
                      onPressed:
                          item.order <= 0 ? null : () => _moveGallery(-1),
                      icon: const Icon(Icons.arrow_upward),
                      tooltip: 'Subir',
                    ),
                    IconButton(
                      onPressed: item.order >= events.length
                          ? null
                          : () => _moveGallery(1),
                      icon: const Icon(Icons.arrow_downward),
                      tooltip: 'Descer',
                    ),
                    IconButton(
                      onPressed: () => _openGallerySheet(context),
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Editar carrossel',
                    ),
                  ],
                  trailing: _HomeGalleryThumbs(images: galleryImages),
                  onTap: () => _openGallerySheet(context),
                );
              }
              final event = events[item.eventIndex!];
              final status = event.hidden ? 'Oculto' : 'Visível';
              return _AdminTile(
                icon: _homeEventIcon(item.eventIndex!),
                title: event.title,
                subtitle:
                    '$status • ${_formatAdminDate(event.date)} • ${_homeCountDirectionLabel(event.countDirection)} • ${event.message}',
                actions: [
                  IconButton(
                    onPressed: item.order <= 0
                        ? null
                        : () => _moveEvent(item.eventIndex!, -1),
                    icon: const Icon(Icons.arrow_upward),
                    tooltip: 'Subir',
                  ),
                  IconButton(
                    onPressed: item.order >= items.length - 1
                        ? null
                        : () => _moveEvent(item.eventIndex!, 1),
                    icon: const Icon(Icons.arrow_downward),
                    tooltip: 'Descer',
                  ),
                  IconButton(
                    onPressed: () => _toggleHidden(item.eventIndex!),
                    icon: Icon(event.hidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    tooltip: event.hidden ? 'Mostrar' : 'Ocultar',
                  ),
                  IconButton(
                    onPressed: () =>
                        _openEventSheet(context, index: item.eventIndex),
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    onPressed: events.length <= 1
                        ? null
                        : () => _deleteEvent(item.eventIndex!),
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remover',
                  ),
                ],
                onTap: () => _openEventSheet(context, index: item.eventIndex),
              );
            },
          ),
        ),
      ],
    );
  }

  List<_HomeAdminItem> _homeAdminItems() {
    final items = <_HomeAdminItem>[];
    final galleryOrder = _normalizedGalleryOrder;
    for (var index = 0; index <= events.length; index++) {
      if (index == galleryOrder) items.add(_HomeAdminItem.gallery(index));
      if (index < events.length) items.add(_HomeAdminItem.event(index));
    }
    return items;
  }

  Future<void> _save({
    List<HomeEventConfig>? nextEvents,
    List<String>? nextGalleryImages,
    int? nextGalleryOrder,
  }) {
    final eventsToSave = nextEvents ?? events;
    return onSave(HomeSettingsConfig(
      events: eventsToSave,
      galleryImages: nextGalleryImages ?? galleryImages,
      galleryOrder: (nextGalleryOrder ?? _normalizedGalleryOrder)
          .clamp(0, eventsToSave.length),
    ));
  }

  Future<void> _openEventSheet(BuildContext context, {int? index}) async {
    final current = index == null ? null : events[index];
    final draft = current == null
        ? _HomeEventDraft.empty()
        : _HomeEventDraft.fromEvent(current);
    final saved = await showAppSheet<HomeEventConfig>(
      context: context,
      builder: (_) => _HomeEventSheet(draft: draft, isNew: current == null),
    );
    draft.dispose();
    if (saved == null) return;
    final nextEvents = [...events];
    var nextGalleryOrder = _normalizedGalleryOrder;
    if (index == null) {
      nextEvents.add(saved);
      if (nextGalleryOrder == events.length) {
        nextGalleryOrder = nextEvents.length;
      }
    } else {
      nextEvents[index] = saved;
    }
    await _save(nextEvents: nextEvents, nextGalleryOrder: nextGalleryOrder);
  }

  Future<void> _openGallerySheet(BuildContext context) async {
    final images = await showAppSheet<List<String>>(
      context: context,
      builder: (_) => _HomeGallerySheet(
        images: galleryImages,
        repository: repository,
      ),
    );
    if (images == null) return;
    await _save(nextGalleryImages: images);
  }

  Future<void> _deleteEvent(int index) async {
    final nextEvents = [...events]..removeAt(index);
    var nextGalleryOrder = _normalizedGalleryOrder;
    if (index < nextGalleryOrder) nextGalleryOrder--;
    await _save(nextEvents: nextEvents, nextGalleryOrder: nextGalleryOrder);
  }

  Future<void> _toggleHidden(int index) async {
    final event = events[index];
    final nextEvents = [...events];
    nextEvents[index] = HomeEventConfig(
      title: event.title,
      icon: event.icon,
      date: event.date,
      message: event.message,
      countDirection: event.countDirection,
      hidden: !event.hidden,
    );
    await _save(nextEvents: nextEvents);
  }

  Future<void> _moveGallery(int offset) {
    return _save(nextGalleryOrder: _normalizedGalleryOrder + offset);
  }

  Future<void> _moveEvent(int index, int offset) async {
    final target = index + offset;
    if (target < 0 || target >= events.length) return;
    final nextEvents = [...events];
    final event = nextEvents.removeAt(index);
    nextEvents.insert(target, event);
    var nextGalleryOrder = _normalizedGalleryOrder;
    if (index < nextGalleryOrder && target >= nextGalleryOrder) {
      nextGalleryOrder--;
    } else if (index > nextGalleryOrder && target <= nextGalleryOrder) {
      nextGalleryOrder++;
    }
    await _save(nextEvents: nextEvents, nextGalleryOrder: nextGalleryOrder);
  }
}

class _HomeAdminItem {
  const _HomeAdminItem._({
    required this.order,
    required this.isGallery,
    this.eventIndex,
  });

  factory _HomeAdminItem.event(int index) =>
      _HomeAdminItem._(order: index, isGallery: false, eventIndex: index);

  factory _HomeAdminItem.gallery(int order) =>
      _HomeAdminItem._(order: order, isGallery: true);

  final int order;
  final bool isGallery;
  final int? eventIndex;
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
    final actionBar = trailing == null
        ? Wrap(spacing: 4, children: actions)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              trailing!,
              if (actions.isNotEmpty) ...[
                const SizedBox(width: 8),
                Wrap(spacing: 4, children: actions),
              ],
            ],
          );
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.tone,
    this.onDelete,
  });

  final String label;
  final String tone;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final color = switch (tone) {
      'sent' => const Color(0xff16a34a),
      'failed' => Theme.of(context).colorScheme.error,
      'cancelled' => palette.muted,
      _ => palette.primary,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: .18)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (onDelete != null) ...[
          const SizedBox(width: 4),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Remover agendamento',
          ),
        ],
      ],
    );
  }
}

class _HomeGalleryThumbs extends StatelessWidget {
  const _HomeGalleryThumbs({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    if (images.isEmpty) {
      return Container(
        width: 74,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.primary.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.primary.withValues(alpha: .12)),
        ),
        child: Icon(
          Icons.add_photo_alternate_outlined,
          color: palette.primary,
          size: 22,
        ),
      );
    }
    final preview = images.take(3).toList();
    return SizedBox(
      width: 96,
      height: 46,
      child: Stack(
        children: [
          for (var index = 0; index < preview.length; index++)
            Positioned(
              left: index * 26,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.card, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .10),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    _adminHomeMediaUrl(preview[index]),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image_outlined, size: 18),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _scheduledStatusLabel(String status) {
  return switch (status) {
    'sent' => 'Enviada',
    'failed' => 'Falhou',
    'cancelled' => 'Cancelada',
    _ => 'Pendente',
  };
}

String _formatAdminDateTime(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/'
      '${local.year} ${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

String _formatAdminDate(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/'
      '${local.year}';
}

IconData _homeEventIcon(int index) {
  return switch (index) {
    0 => Icons.favorite_outline,
    1 => Icons.diamond_outlined,
    _ => Icons.child_care_outlined,
  };
}

String _homeCountDirectionLabel(HomeCountDirection direction) {
  return direction == HomeCountDirection.backward
      ? 'Conta para trás'
      : 'Conta para frente';
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

class _HomeEventSheet extends StatefulWidget {
  const _HomeEventSheet({
    required this.draft,
    required this.isNew,
  });

  final _HomeEventDraft draft;
  final bool isNew;

  @override
  State<_HomeEventSheet> createState() => _HomeEventSheetState();
}

class _HomeEventSheetState extends State<_HomeEventSheet> {
  String? errorText;

  void _save() {
    final draft = widget.draft;
    if (!draft.isValid) {
      setState(() => errorText = 'Preencha todos os campos do card.');
      return;
    }
    Navigator.pop(
      context,
      HomeEventConfig(
        title: draft.title.text.trim(),
        icon: draft.icon.text.trim(),
        date: draft.date!,
        message: draft.message.text.trim(),
        countDirection: draft.countDirection,
        hidden: draft.hidden,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return SizedBox(
      width: 560,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSheetHeader(
            title: widget.isNew ? 'Criar card' : 'Editar card',
            subtitle: 'Ajuste o conteúdo e a visibilidade deste card.',
            icon: widget.isNew ? Icons.add : Icons.edit_outlined,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 86,
                child: TextField(
                  controller: draft.icon,
                  decoration: const InputDecoration(labelText: 'Ícone'),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: draft.title,
                  decoration: const InputDecoration(labelText: 'Título'),
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: draft.message,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Mensagem'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 10),
          AppDateField(
            label: 'Data',
            value: draft.date,
            onChanged: (date) => setState(() => draft.date = date),
          ),
          const SizedBox(height: 10),
          SegmentedButton<HomeCountDirection>(
            segments: const [
              ButtonSegment(
                value: HomeCountDirection.forward,
                icon: Icon(Icons.trending_up),
                label: Text('Frente'),
              ),
              ButtonSegment(
                value: HomeCountDirection.backward,
                icon: Icon(Icons.hourglass_bottom_outlined),
                label: Text('Trás'),
              ),
            ],
            selected: {draft.countDirection},
            onSelectionChanged: (value) =>
                setState(() => draft.countDirection = value.first),
          ),
          const SizedBox(height: 10),
          _AdminSwitchRow(
            value: draft.hidden,
            onChanged: (value) => setState(() => draft.hidden = value),
            label: 'Ocultar este card da Home',
          ),
          if (errorText != null) ...[
            const SizedBox(height: 12),
            Text(
              errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 20),
          AppSheetActions(
            onCancel: () => Navigator.pop(context),
            onSave: _save,
          ),
        ],
      ),
    );
  }
}

class _HomeGallerySheet extends StatefulWidget {
  const _HomeGallerySheet({
    required this.images,
    required this.repository,
  });

  final List<String> images;
  final FamilyRepository repository;

  @override
  State<_HomeGallerySheet> createState() => _HomeGallerySheetState();
}

class _HomeGallerySheetState extends State<_HomeGallerySheet> {
  late final List<String> images;
  final imagePicker = ImagePicker();
  bool uploading = false;
  String? errorText;

  @override
  void initState() {
    super.initState();
    images = [...widget.images];
  }

  Future<void> _addImages() async {
    setState(() {
      uploading = true;
      errorText = null;
    });
    try {
      final files = await imagePicker.pickMultiImage(imageQuality: 86);
      for (final file in files) {
        images.add(await widget.repository.uploadPhotoFile(file));
      }
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) setState(() => errorText = _friendlyError(error));
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  void _removeImage(int index) {
    setState(() {
      images.removeAt(index);
      errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 560,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSheetHeader(
            title: 'Carrossel de fotos',
            subtitle: 'Edite as fotos do card flutuante da Home.',
            icon: Icons.auto_awesome_motion_outlined,
          ),
          const SizedBox(height: 18),
          _HomeGalleryEditor(
            images: images,
            uploading: uploading,
            onAdd: uploading ? null : _addImages,
            onRemove: uploading ? null : _removeImage,
          ),
          if (errorText != null) ...[
            const SizedBox(height: 12),
            Text(
              errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 20),
          AppSheetActions(
            onCancel: uploading ? null : () => Navigator.pop(context),
            onSave: uploading ? null : () => Navigator.pop(context, images),
            loading: uploading,
          ),
        ],
      ),
    );
  }
}

class _HomeSettingsSheet extends StatefulWidget {
  const _HomeSettingsSheet({
    required this.events,
    required this.galleryImages,
    required this.repository,
    required this.onSave,
  });

  final List<HomeEventConfig> events;
  final List<String> galleryImages;
  final FamilyRepository repository;
  final Future<void> Function(HomeSettingsConfig settings) onSave;

  @override
  State<_HomeSettingsSheet> createState() => _HomeSettingsSheetState();
}

class _HomeSettingsSheetState extends State<_HomeSettingsSheet> {
  late final List<_HomeEventDraft> drafts;
  late final List<String> galleryImages;
  final imagePicker = ImagePicker();
  bool saving = false;
  bool uploadingImages = false;
  String? errorText;

  @override
  void initState() {
    super.initState();
    drafts = widget.events.map(_HomeEventDraft.fromEvent).toList();
    if (drafts.isEmpty) drafts.add(_HomeEventDraft.empty());
    galleryImages = [...widget.galleryImages];
  }

  @override
  void dispose() {
    for (final draft in drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (drafts.any((draft) => !draft.isValid)) {
      setState(() => errorText = 'Preencha todos os campos dos cards.');
      return;
    }
    setState(() {
      saving = true;
      errorText = null;
    });
    try {
      final events = List.generate(
        drafts.length,
        (index) => HomeEventConfig(
          title: drafts[index].title.text.trim(),
          icon: drafts[index].icon.text.trim(),
          date: drafts[index].date!,
          message: drafts[index].message.text.trim(),
          countDirection: drafts[index].countDirection,
          hidden: drafts[index].hidden,
        ),
      );
      await widget.onSave(
        HomeSettingsConfig(
          events: events,
          galleryImages: galleryImages,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => errorText = _friendlyError(error));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _addCard() {
    setState(() {
      drafts.add(_HomeEventDraft.empty());
      errorText = null;
    });
  }

  void _removeCard(int index) {
    if (drafts.length == 1) {
      setState(() => errorText = 'Mantenha pelo menos um card na Home.');
      return;
    }
    setState(() {
      final removed = drafts.removeAt(index);
      removed.dispose();
      errorText = null;
    });
  }

  void _moveCard(int index, int offset) {
    final target = index + offset;
    if (target < 0 || target >= drafts.length) return;
    setState(() {
      final draft = drafts.removeAt(index);
      drafts.insert(target, draft);
    });
  }

  Future<void> _addGalleryImages() async {
    setState(() {
      uploadingImages = true;
      errorText = null;
    });
    try {
      final files = await imagePicker.pickMultiImage(imageQuality: 86);
      if (files.isEmpty) return;
      for (final file in files) {
        final path = await widget.repository.uploadPhotoFile(file);
        galleryImages.add(path);
      }
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) setState(() => errorText = _friendlyError(error));
    } finally {
      if (mounted) setState(() => uploadingImages = false);
    }
  }

  void _removeGalleryImage(int index) {
    setState(() {
      galleryImages.removeAt(index);
      errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return SizedBox(
      width: 560,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSheetHeader(
            title: 'Cards da Home',
            subtitle: 'Ajuste ordem, título, ícone, mensagem, data e contagem.',
            icon: Icons.dashboard_customize_outlined,
          ),
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .58,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: drafts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final draft = drafts[index];
                return LovePanel(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: palette.primary.withValues(alpha: .10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: palette.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Card ${index + 1}',
                              style: TextStyle(
                                color: palette.foreground,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: saving || index == 0
                                ? null
                                : () => _moveCard(index, -1),
                            icon: const Icon(Icons.arrow_upward),
                            tooltip: 'Subir',
                          ),
                          IconButton(
                            onPressed: saving || index == drafts.length - 1
                                ? null
                                : () => _moveCard(index, 1),
                            icon: const Icon(Icons.arrow_downward),
                            tooltip: 'Descer',
                          ),
                          IconButton(
                            onPressed: saving ? null : () => _removeCard(index),
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Remover card',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          SizedBox(
                            width: 86,
                            child: TextField(
                              controller: draft.icon,
                              enabled: !saving,
                              decoration:
                                  const InputDecoration(labelText: 'Ícone'),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: draft.title,
                              enabled: !saving,
                              decoration:
                                  const InputDecoration(labelText: 'Título'),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: draft.message,
                        enabled: !saving,
                        minLines: 2,
                        maxLines: 3,
                        decoration:
                            const InputDecoration(labelText: 'Mensagem'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 10),
                      AppDateField(
                        label: 'Data',
                        value: draft.date,
                        onChanged: saving
                            ? (_) {}
                            : (date) => setState(() => draft.date = date),
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<HomeCountDirection>(
                        segments: const [
                          ButtonSegment(
                            value: HomeCountDirection.forward,
                            icon: Icon(Icons.trending_up),
                            label: Text('Frente'),
                          ),
                          ButtonSegment(
                            value: HomeCountDirection.backward,
                            icon: Icon(Icons.hourglass_bottom_outlined),
                            label: Text('Trás'),
                          ),
                        ],
                        selected: {draft.countDirection},
                        onSelectionChanged: saving
                            ? null
                            : (value) => setState(
                                  () => draft.countDirection = value.first,
                                ),
                      ),
                      const SizedBox(height: 10),
                      _AdminSwitchRow(
                        value: draft.hidden,
                        onChanged: saving
                            ? (_) {}
                            : (value) => setState(() => draft.hidden = value),
                        label: 'Ocultar este card da Home',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              onPressed: saving ? null : _addCard,
              label: 'Adicionar card',
              icon: Icons.add,
            ),
          ),
          const SizedBox(height: 18),
          _HomeGalleryEditor(
            images: galleryImages,
            uploading: uploadingImages,
            onAdd: saving || uploadingImages ? null : _addGalleryImages,
            onRemove: saving || uploadingImages ? null : _removeGalleryImage,
          ),
          if (errorText != null) ...[
            const SizedBox(height: 12),
            Text(
              errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 20),
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

class _HomeGalleryEditor extends StatelessWidget {
  const _HomeGalleryEditor({
    required this.images,
    required this.uploading,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> images;
  final bool uploading;
  final VoidCallback? onAdd;
  final ValueChanged<int>? onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return LovePanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library_outlined, color: palette.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Carrossel de fotos',
                  style: TextStyle(
                    color: palette.foreground,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              AppButton(
                onPressed: onAdd,
                label: uploading ? 'Enviando...' : 'Adicionar fotos',
                icon: Icons.add_photo_alternate_outlined,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (images.isEmpty)
            Text(
              'Nenhuma foto no carrossel.',
              style: TextStyle(
                color: palette.muted,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            SizedBox(
              height: 104,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final image = images[index];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          _adminHomeMediaUrl(image),
                          width: 128,
                          height: 104,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 128,
                            height: 104,
                            color: palette.primary.withValues(alpha: .08),
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Material(
                          color: Colors.black.withValues(alpha: .48),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onRemove == null
                                ? null
                                : () => onRemove!(index),
                            child: const Padding(
                              padding: EdgeInsets.all(5),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

String _adminHomeMediaUrl(String url) {
  if (url.startsWith('http')) return url;
  return AppConfig.apiUri('/fotos/file?path=${Uri.encodeQueryComponent(url)}')
      .toString();
}

class _HomeEventDraft {
  _HomeEventDraft({
    required this.title,
    required this.icon,
    required this.message,
    required this.date,
    required this.countDirection,
    required this.hidden,
  });

  factory _HomeEventDraft.fromEvent(HomeEventConfig event) => _HomeEventDraft(
        title: TextEditingController(text: event.title),
        icon: TextEditingController(text: event.icon),
        message: TextEditingController(text: event.message),
        date: event.date,
        countDirection: event.countDirection,
        hidden: event.hidden,
      );

  factory _HomeEventDraft.empty() => _HomeEventDraft(
        title: TextEditingController(),
        icon: TextEditingController(text: '💗'),
        message: TextEditingController(),
        date: DateTime.now(),
        countDirection: HomeCountDirection.forward,
        hidden: false,
      );

  final TextEditingController title;
  final TextEditingController icon;
  final TextEditingController message;
  DateTime? date;
  HomeCountDirection countDirection;
  bool hidden;

  bool get isValid =>
      title.text.trim().isNotEmpty &&
      icon.text.trim().isNotEmpty &&
      message.text.trim().isNotEmpty &&
      date != null;

  void dispose() {
    title.dispose();
    icon.dispose();
    message.dispose();
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
  late final TextEditingController password;
  late final TextEditingController confirmPassword;
  late String role;
  late Set<String> access;
  bool saving = false;
  bool obscurePassword = true;
  String? errorText;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.user.name ?? '');
    password = TextEditingController();
    confirmPassword = TextEditingController();
    role =
        appUserRoles.contains(widget.user.role) ? widget.user.role : 'member';
    access = widget.user.access.toSet();
  }

  @override
  void dispose() {
    name.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nextPassword = password.text.trim();
    if (nextPassword.isNotEmpty && nextPassword.length < 8) {
      setState(() => errorText = 'A senha deve ter pelo menos 8 caracteres.');
      return;
    }
    if (nextPassword != confirmPassword.text.trim()) {
      setState(() => errorText = 'A confirmação da senha não confere.');
      return;
    }
    setState(() => saving = true);
    try {
      final data = <String, dynamic>{
        'name': name.text,
        'role': role,
        'access': access.toList(),
      };
      if (nextPassword.isNotEmpty) data['password'] = nextPassword;
      await widget.onSave(data);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() => errorText = _friendlyError(error));
      }
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
            subtitle: 'Ajuste o nome, acesso e senha desta conta.',
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
          TextField(
            controller: password,
            obscureText: obscurePassword,
            decoration: InputDecoration(
              labelText: 'Nova senha',
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => obscurePassword = !obscurePassword),
                icon: Icon(obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                tooltip: obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
              ),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: confirmPassword,
            obscureText: obscurePassword,
            decoration: const InputDecoration(labelText: 'Confirmar senha'),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 10),
            Text(
              errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
            role == 'owner' || role == 'admin'
                ? 'Proprietários e administradores acessam tudo automaticamente.'
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
  String? errorText;

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
    final titleText = title.text.trim();
    if (titleText.isEmpty) {
      setState(() => errorText = 'Informe o título da notificação.');
      return;
    }
    setState(() => saving = true);
    try {
      await widget.onSave({
        'title': titleText,
        'body': body.text,
        'url': url.text.trim().isEmpty ? '/' : url.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() => errorText = _friendlyError(error));
      }
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
          if (errorText != null) ...[
            const SizedBox(height: 10),
            Text(
              errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
    this.notification,
    required this.onSchedule,
  });

  final AppNotification? notification;
  final Future<void> Function({
    required String title,
    String? body,
    String? url,
    required DateTime scheduledAt,
  }) onSchedule;

  @override
  State<_ScheduleNotificationSheet> createState() =>
      _ScheduleNotificationSheetState();
}

class _ScheduleNotificationSheetState
    extends State<_ScheduleNotificationSheet> {
  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  late final TextEditingController title;
  late final TextEditingController body;
  late final TextEditingController url;
  bool saving = false;
  String? errorText;

  @override
  void initState() {
    super.initState();
    final notification = widget.notification;
    title = TextEditingController(text: notification?.title ?? '');
    body = TextEditingController(text: notification?.body ?? '');
    url = TextEditingController(text: notification?.url ?? '/');
    _setDateTime(DateTime.now().add(const Duration(minutes: 10)));
  }

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    url.dispose();
    super.dispose();
  }

  DateTime get scheduledAt => DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

  void _setDateTime(DateTime value) {
    selectedDate = DateTime(value.year, value.month, value.day);
    selectedTime = TimeOfDay.fromDateTime(value);
  }

  void _setPreset(Duration offset) {
    setState(() {
      _setDateTime(DateTime.now().add(offset));
      errorText = null;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.isBefore(now) ? now : selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        if (!scheduledAt.isAfter(now)) {
          _setDateTime(now.add(const Duration(minutes: 10)));
        }
        errorText = null;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
        errorText = null;
      });
    }
  }

  Future<void> _schedule() async {
    final titleText = title.text.trim();
    if (titleText.isEmpty) {
      setState(() => errorText = 'Informe o título da notificação.');
      return;
    }
    if (!scheduledAt.isAfter(DateTime.now())) {
      setState(() => errorText = 'Escolha uma data e horário no futuro.');
      return;
    }
    setState(() => saving = true);
    try {
      await widget.onSchedule(
        title: titleText,
        body: body.text.trim(),
        url: url.text.trim().isEmpty ? '/' : url.text.trim(),
        scheduledAt: scheduledAt,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() => errorText = _friendlyError(error));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return SizedBox(
      width: 540,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSheetHeader(
            title: 'Agendar notificação',
            subtitle: 'Defina a mensagem e quando a família deve receber.',
            icon: Icons.schedule_send_outlined,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: title,
            decoration: const InputDecoration(labelText: 'Título'),
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (errorText != null) setState(() => errorText = null);
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: body,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Mensagem'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: url,
            decoration: const InputDecoration(labelText: 'Rota ao abrir'),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _schedule(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.timer_outlined, size: 18),
                label: const Text('Em 10 min'),
                onPressed: saving
                    ? null
                    : () => _setPreset(const Duration(minutes: 10)),
              ),
              ActionChip(
                avatar: const Icon(Icons.schedule_outlined, size: 18),
                label: const Text('Em 1 hora'),
                onPressed:
                    saving ? null : () => _setPreset(const Duration(hours: 1)),
              ),
              ActionChip(
                avatar: const Icon(Icons.today_outlined, size: 18),
                label: const Text('Amanhã'),
                onPressed:
                    saving ? null : () => _setPreset(const Duration(days: 1)),
              ),
            ],
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
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: palette.primary.withValues(alpha: .16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.event_available_outlined,
                    color: palette.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Agendado para ${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year} às ${selectedTime.format(context)}',
                    style: TextStyle(
                      color: palette.foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 10),
            Text(
              errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
  late final List<List<TextEditingController>> itemFields;
  bool active = true;
  bool saving = false;
  String? formError;

  @override
  void initState() {
    super.initState();
    final current = widget.miniGame;
    type = current?.type ?? miniGameTypes.first;
    title = TextEditingController(text: current?.title ?? '');
    instructions = TextEditingController(text: current?.instructions ?? '');
    itemFields = [
      for (final item in current?.items ?? const <String>[])
        _fieldsForItem(type, item),
    ];
    if (itemFields.isEmpty) itemFields.add(_emptyFields(type));
    active = current?.active ?? true;
  }

  @override
  void dispose() {
    title.dispose();
    instructions.dispose();
    for (final fields in itemFields) {
      for (final field in fields) {
        field.dispose();
      }
    }
    super.dispose();
  }

  List<TextEditingController> _fieldsForItem(String type, String item) {
    final parts = item.split('|').map((part) => part.trim()).toList();
    if (type == 'this_or_that') {
      return [
        TextEditingController(text: parts.isNotEmpty ? parts[0] : ''),
        TextEditingController(text: parts.length > 1 ? parts[1] : ''),
        TextEditingController(text: parts.length > 2 ? parts[2] : ''),
      ];
    }
    return [TextEditingController(text: item.trim())];
  }

  List<TextEditingController> _emptyFields(String type) {
    if (type == 'this_or_that') {
      return [
        TextEditingController(),
        TextEditingController(),
        TextEditingController(),
      ];
    }
    return [TextEditingController()];
  }

  void _addItem() {
    setState(() => itemFields.add(_emptyFields(type)));
  }

  void _removeItem(int index) {
    if (itemFields.length == 1) {
      for (final field in itemFields[index]) {
        field.clear();
      }
      setState(() {});
      return;
    }
    final removed = itemFields.removeAt(index);
    for (final field in removed) {
      field.dispose();
    }
    setState(() {});
  }

  List<String> _serializedItems() {
    return itemFields
        .map((fields) {
          if (type == 'this_or_that') {
            final values = fields.map((field) => field.text.trim()).toList();
            if (values.length < 3 || values.any((value) => value.isEmpty)) {
              return '';
            }
            return values.take(3).join('|');
          }
          return fields.first.text.trim();
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String get _itemsTitle {
    return switch (type) {
      'memory_match' => 'Pares da memória',
      'love_order' => 'Passos da linha',
      'this_or_that' => 'Rodadas de escolha',
      _ => 'Itens',
    };
  }

  String get _itemsHelp {
    return switch (type) {
      'memory_match' => 'Cada item vira um par no jogo da memória.',
      'love_order' => 'A ordem cadastrada aqui será a ordem correta do jogo.',
      'this_or_that' =>
        'Cada rodada tem uma pergunta e duas opções. Não existe resposta certa.',
      _ => 'Cadastre os itens do jogo.',
    };
  }

  Future<void> _save() async {
    final items = _serializedItems();
    if (title.text.trim().isEmpty || items.isEmpty) {
      setState(() {
        formError = title.text.trim().isEmpty
            ? 'Informe o título do jogo.'
            : 'Cadastre pelo menos um item completo.';
      });
      return;
    }
    setState(() => saving = true);
    try {
      await widget.onSave({
        'type': type,
        'title': title.text.trim(),
        'instructions': instructions.text,
        'items': items,
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
      width: 620,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSheetHeader(
            title: widget.miniGame == null
                ? 'Novo ${_miniGameAdminLabel(type)}'
                : 'Editar ${_miniGameAdminLabel(type)}',
            subtitle: _itemsHelp,
            icon: _miniGameAdminIcon(type),
          ),
          const SizedBox(height: 14),
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
          _MiniGameItemsEditor(
            title: _itemsTitle,
            type: type,
            fields: itemFields,
            onAdd: _addItem,
            onRemove: _removeItem,
          ),
          if (formError != null) ...[
            const SizedBox(height: 8),
            Text(
              formError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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

class _MiniGameItemsEditor extends StatelessWidget {
  const _MiniGameItemsEditor({
    required this.title,
    required this.type,
    required this.fields,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final String type;
  final List<List<TextEditingController>> fields;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.bgStart.withValues(alpha: .42),
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  tooltip: 'Adicionar',
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < fields.length; index++) ...[
              _MiniGameItemFields(
                type: type,
                index: index,
                fields: fields[index],
                onRemove: () => onRemove(index),
              ),
              if (index != fields.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniGameItemFields extends StatelessWidget {
  const _MiniGameItemFields({
    required this.type,
    required this.index,
    required this.fields,
    required this.onRemove,
  });

  final String type;
  final int index;
  final List<TextEditingController> fields;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.card.withValues(alpha: .70),
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${index + 1}. ${_miniGameItemTitle(type)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remover',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (type == 'this_or_that')
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 420;
                  final optionA = TextField(
                    controller: fields[1],
                    decoration: const InputDecoration(labelText: 'Opção A'),
                    textInputAction: TextInputAction.next,
                  );
                  final optionB = TextField(
                    controller: fields[2],
                    decoration: const InputDecoration(labelText: 'Opção B'),
                    textInputAction: TextInputAction.next,
                  );
                  return Column(
                    children: [
                      TextField(
                        controller: fields[0],
                        decoration:
                            const InputDecoration(labelText: 'Pergunta'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 8),
                      if (compact)
                        Column(
                          children: [
                            optionA,
                            const SizedBox(height: 8),
                            optionB,
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(child: optionA),
                            const SizedBox(width: 8),
                            Expanded(child: optionB),
                          ],
                        ),
                    ],
                  );
                },
              )
            else
              TextField(
                controller: fields.first,
                decoration:
                    InputDecoration(labelText: _miniGameItemLabel(type)),
                textInputAction: TextInputAction.next,
              ),
          ],
        ),
      ),
    );
  }
}

String _miniGameItemTitle(String type) {
  return switch (type) {
    'memory_match' => 'Par',
    'love_order' => 'Passo',
    'this_or_that' => 'Rodada',
    _ => 'Item',
  };
}

String _miniGameItemLabel(String type) {
  return switch (type) {
    'memory_match' => 'Texto do par',
    'love_order' => 'Momento da história',
    _ => 'Item',
  };
}
