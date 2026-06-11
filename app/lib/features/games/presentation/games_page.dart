import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/api/query_keys.dart';
import '../../../core/query/app_query.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_fixed_header_scroll_view.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/love_action_card.dart';
import '../../../core/widgets/love_background.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../data/family_repository.dart';
import '../../../data/models.dart';

enum _GameView { hub, quiz, wordSearch, memoryMatch, loveOrder, thisOrThat }

class GamesPage extends StatefulWidget {
  const GamesPage({
    super.key,
    required this.repository,
    required this.toast,
    required this.auth,
  });

  final FamilyRepository repository;
  final ToastController toast;
  final AuthController auth;

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  _GameView view = _GameView.hub;
  int version = 0;

  @override
  void initState() {
    super.initState();
    for (final event in _gameRealtimeEvents) {
      widget.repository.socket.on(event, _handleRealtimeChange);
    }
  }

  @override
  void dispose() {
    for (final event in _gameRealtimeEvents) {
      widget.repository.socket.off(event, _handleRealtimeChange);
    }
    super.dispose();
  }

  void _handleRealtimeChange(dynamic _) {
    if (!mounted) return;
    setState(() => version++);
  }

  @override
  Widget build(BuildContext context) {
    return LoveBackground(
      child: switch (view) {
        _GameView.hub => _GamesHub(
            key: ValueKey('hub-$version'),
            repository: widget.repository,
            onOpen: (next) => setState(() => view = next),
          ),
        _GameView.quiz => _QuizGame(
            key: ValueKey('quiz-$version'),
            repository: widget.repository,
            toast: widget.toast,
            auth: widget.auth,
            onBack: () => setState(() => view = _GameView.hub),
          ),
        _GameView.wordSearch => _WordSearchGame(
            key: ValueKey('words-$version'),
            repository: widget.repository,
            toast: widget.toast,
            auth: widget.auth,
            onBack: () => setState(() => view = _GameView.hub),
          ),
        _GameView.memoryMatch => _MiniGameRoute(
            key: ValueKey('memory-$version'),
            type: 'memory_match',
            repository: widget.repository,
            toast: widget.toast,
            auth: widget.auth,
            onBack: () => setState(() => view = _GameView.hub),
            builder: (config, common) =>
                _MemoryMatchGame(config: config, common: common),
          ),
        _GameView.loveOrder => _MiniGameRoute(
            key: ValueKey('order-$version'),
            type: 'love_order',
            repository: widget.repository,
            toast: widget.toast,
            auth: widget.auth,
            onBack: () => setState(() => view = _GameView.hub),
            builder: (config, common) =>
                _LoveOrderGame(config: config, common: common),
          ),
        _GameView.thisOrThat => _MiniGameRoute(
            key: ValueKey('choice-$version'),
            type: 'this_or_that',
            repository: widget.repository,
            toast: widget.toast,
            auth: widget.auth,
            onBack: () => setState(() => view = _GameView.hub),
            builder: (config, common) =>
                _ThisOrThatGame(config: config, common: common),
          ),
      },
    );
  }
}

const _gameRealtimeEvents = [
  'games.quiz.created',
  'games.quiz.updated',
  'games.quiz.deleted',
  'games.words.created',
  'games.words.updated',
  'games.words.deleted',
  'games.mini.created',
  'games.mini.updated',
  'games.mini.deleted',
];

class _GamesHub extends StatelessWidget {
  const _GamesHub({super.key, required this.repository, required this.onOpen});

  final FamilyRepository repository;
  final ValueChanged<_GameView> onOpen;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return AppFixedHeaderScrollView(
      onRefresh: () async {},
      header: const _GamesHero(),
      headerGap: 14,
      children: [
        AppQuery<List<MiniGameConfig>>(
          queryKey: QueryKeys.miniGames(),
          queryFn: repository.listMiniGames,
          loading: const SkeletonBox(height: 260, borderRadius: 8),
          builder: (context, miniGames, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 820;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: wide ? 2 : 1,
                  childAspectRatio: wide ? 2.45 : 1.86,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  children: [
                    _GameCard(
                      icon: Icons.favorite,
                      title: 'Quiz do Amor',
                      body:
                          'Perguntas dinâmicas para testar carinho, memória e pequenos detalhes da família.',
                      color: palette.primary,
                      accent: palette.primaryDark,
                      metric: 'Quiz',
                      details: const ['Respostas rápidas'],
                      footer: 'Perguntas editáveis pelo admin',
                      onTap: () => onOpen(_GameView.quiz),
                    ),
                    _GameCard(
                      icon: Icons.grid_on,
                      title: 'Caça Palavras',
                      body:
                          'Palavras familiares e românticas sorteadas a cada partida.',
                      color: palette.primaryDark,
                      accent: palette.primary,
                      metric: '12x12',
                      details: const ['Arraste nas letras'],
                      footer: 'Palavras editáveis pelo admin',
                      onTap: () => onOpen(_GameView.wordSearch),
                    ),
                    for (final config in miniGames)
                      _GameCard(
                        icon: _miniGameIcon(config.type),
                        title: config.title,
                        body: config.instructions,
                        color: palette.primary,
                        accent: palette.primaryDark,
                        metric: _miniGameMetric(config),
                        details: [_miniGameTypeLabel(config.type)],
                        footer: 'Configurável pelo admin',
                        onTap: () => onOpen(_viewForMiniGame(config.type)),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _GamesHero extends StatelessWidget {
  const _GamesHero();

  @override
  Widget build(BuildContext context) {
    return const AppPageHeader(
      title: 'Jogos do Amor',
      subtitle: 'Quiz e caça-palavras em um só lugar.',
      icon: Icons.sports_esports_outlined,
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    required this.accent,
    required this.metric,
    required this.details,
    required this.footer,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final Color accent;
  final String metric;
  final List<String> details;
  final String footer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: LovePanel(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 74,
                height: double.infinity,
                constraints: const BoxConstraints(minHeight: 104),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: .92),
                      accent.withValues(alpha: .92),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 30),
                    const SizedBox(height: 8),
                    Text(
                      metric,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.foreground,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.muted,
                        height: 1.32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: color, size: 16),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            details.first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.foreground,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            footer,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: color),
                      ],
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

class _QuizGame extends StatefulWidget {
  const _QuizGame({
    super.key,
    required this.repository,
    required this.toast,
    required this.auth,
    required this.onBack,
  });

  final FamilyRepository repository;
  final ToastController toast;
  final AuthController auth;
  final VoidCallback onBack;

  @override
  State<_QuizGame> createState() => _QuizGameState();
}

class _QuizGameState extends State<_QuizGame> {
  final name = TextEditingController();
  int index = 0;
  int score = 0;
  bool finished = false;

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  void _restart() {
    setState(() {
      index = 0;
      score = 0;
      finished = false;
    });
  }

  Future<void> _answer(List<QuizQuestion> questions, int selected) async {
    final question = questions[index];
    if (selected == question.correctIndex) score++;
    if (index + 1 < questions.length) {
      setState(() => index++);
      return;
    }
    setState(() => finished = true);
    await widget.repository.completeGame(
      game: 'quiz',
      playerName: name.text,
      score: score,
      total: questions.length,
    );
    widget.toast.backendSuccess(widget.repository.takeMessage());
  }

  @override
  Widget build(BuildContext context) {
    return AppFixedHeaderScrollView(
      onRefresh: () async =>
          invalidateQueries(context, QueryKeys.quizQuestions()),
      header: _GamePlayHeader(
        title: 'Quiz do Amor',
        subtitle: 'Responda uma pergunta por vez.',
        icon: Icons.favorite_outline,
        onBack: widget.onBack,
      ),
      headerGap: 14,
      children: [
        _GamePanel(
          child: AppQuery<List<QuizQuestion>>(
            queryKey: QueryKeys.quizQuestions(),
            queryFn: widget.repository.listQuizQuestions,
            loading: const Center(child: CircularProgressIndicator()),
            builder: (context, questions, _) {
              if (questions.isEmpty) {
                return const _GameEmptyState(
                    text: 'Nenhuma pergunta ativa no momento.');
              }
              if (index >= questions.length) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _restart();
                });
              }
              return finished
                  ? _QuizFinished(
                      score: score,
                      total: questions.length,
                      onRestart: _restart,
                    )
                  : _QuizQuestionView(
                      question: questions[index],
                      index: index,
                      total: questions.length,
                      name: name,
                      showName: widget.auth.user == null,
                      onAnswer: (selected) => _answer(questions, selected),
                    );
            },
          ),
        ),
      ],
    );
  }
}

class _QuizQuestionView extends StatelessWidget {
  const _QuizQuestionView({
    required this.question,
    required this.index,
    required this.total,
    required this.name,
    required this.showName,
    required this.onAnswer,
  });

  final QuizQuestion question;
  final int index;
  final int total;
  final TextEditingController name;
  final bool showName;
  final ValueChanged<int> onAnswer;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : (index + 1) / total,
                minHeight: 8,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 12),
            Text('${index + 1}/$total',
                style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 18),
        Text(question.question,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 18),
        if (showName) ...[
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Seu nome'),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
          ),
          const SizedBox(height: 12),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 680 ? 2 : 1;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              childAspectRatio: columns == 2 ? 4.2 : 6.0,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                for (var i = 0; i < question.options.length; i++)
                  OutlinedButton.icon(
                    onPressed: () => onAnswer(i),
                    icon: Icon(Icons.favorite_border, color: palette.primary),
                    label: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        question.options[i],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _WordSearchGame extends StatefulWidget {
  const _WordSearchGame({
    super.key,
    required this.repository,
    required this.toast,
    required this.auth,
    required this.onBack,
  });

  final FamilyRepository repository;
  final ToastController toast;
  final AuthController auth;
  final VoidCallback onBack;

  @override
  State<_WordSearchGame> createState() => _WordSearchGameState();
}

class _WordSearchGameState extends State<_WordSearchGame> {
  final name = TextEditingController();
  List<GameWord> gameWords = [];
  late List<String> words;
  late _WordPuzzle puzzle;
  final Set<String> found = {};
  final Set<int> foundCells = {};
  final List<int> selectedCells = [];
  int? dragStart;

  @override
  void initState() {
    super.initState();
    words = [];
    puzzle = _WordPuzzle.empty();
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  void _newGame([List<GameWord>? source]) {
    gameWords = source ?? gameWords;
    words = _randomWords(gameWords);
    puzzle = _generateWordPuzzle(words);
    found.clear();
    foundCells.clear();
    selectedCells.clear();
    dragStart = null;
  }

  Future<void> _completeWord(String word, List<int> path) async {
    setState(() {
      found.add(word);
      foundCells.addAll(path);
      selectedCells.clear();
      dragStart = null;
    });
    if (found.length == words.length) {
      await widget.repository.completeGame(
        game: 'word_search',
        playerName: name.text,
        score: found.length,
        total: words.length,
      );
      widget.toast.backendSuccess(widget.repository.takeMessage());
    }
  }

  void _startSelection(int index) {
    setState(() {
      dragStart = index;
      selectedCells
        ..clear()
        ..add(index);
    });
  }

  void _updateSelection(int index) {
    final start = dragStart;
    if (start == null) return;
    final path = _linePath(start, index, puzzle.size);
    if (path.isEmpty) return;
    setState(() {
      selectedCells
        ..clear()
        ..addAll(path);
    });
  }

  Future<void> _endSelection() async {
    if (selectedCells.isEmpty) return;
    final selectedText = selectedCells
        .map((index) =>
            puzzle.letters[index ~/ puzzle.size][index % puzzle.size])
        .join();
    for (final word in words) {
      if (found.contains(word)) continue;
      if (selectedText == word ||
          selectedText.split('').reversed.join() == word) {
        await _completeWord(word, List<int>.from(selectedCells));
        return;
      }
    }
    setState(() {
      selectedCells.clear();
      dragStart = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppFixedHeaderScrollView(
      onRefresh: () async =>
          invalidateQueries(context, QueryKeys.wordSearchWords()),
      header: _GamePlayHeader(
        title: 'Caça Palavras',
        subtitle: 'Arraste sobre as letras para formar cada palavra.',
        icon: Icons.grid_on_outlined,
        onBack: widget.onBack,
      ),
      headerGap: 14,
      children: [
        _GamePanel(
          child: AppQuery<List<GameWord>>(
            queryKey: QueryKeys.wordSearchWords(),
            queryFn: widget.repository.listGameWords,
            loading: const SkeletonBox(height: 320, borderRadius: 8),
            builder: (context, remoteWords, _) {
              if (_wordsChanged(remoteWords) || words.isEmpty) {
                _newGame(remoteWords);
              }
              return _WordSearchContent(
                name: name,
                showName: widget.auth.user == null,
                puzzle: puzzle,
                words: words,
                found: found,
                foundCells: foundCells,
                selectedCells: selectedCells,
                onSelectionStart: _startSelection,
                onSelectionUpdate: _updateSelection,
                onSelectionEnd: _endSelection,
                onNewGame: () => setState(_newGame),
              );
            },
          ),
        ),
      ],
    );
  }

  bool _wordsChanged(List<GameWord> next) {
    if (gameWords.length != next.length) return true;
    for (var i = 0; i < next.length; i++) {
      if (gameWords[i].id != next[i].id ||
          gameWords[i].word != next[i].word ||
          gameWords[i].active != next[i].active) {
        return true;
      }
    }
    return false;
  }
}

class _WordSearchContent extends StatelessWidget {
  const _WordSearchContent({
    required this.name,
    required this.showName,
    required this.puzzle,
    required this.words,
    required this.found,
    required this.foundCells,
    required this.selectedCells,
    required this.onSelectionStart,
    required this.onSelectionUpdate,
    required this.onSelectionEnd,
    required this.onNewGame,
  });

  final TextEditingController name;
  final bool showName;
  final _WordPuzzle puzzle;
  final List<String> words;
  final Set<String> found;
  final Set<int> foundCells;
  final List<int> selectedCells;
  final ValueChanged<int> onSelectionStart;
  final ValueChanged<int> onSelectionUpdate;
  final Future<void> Function() onSelectionEnd;
  final VoidCallback onNewGame;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final progress = words.isEmpty ? 0.0 : found.length / words.length;
    final board = _WordSearchBoard(
      puzzle: puzzle,
      foundCells: foundCells,
      selectedCells: selectedCells,
      onSelectionStart: onSelectionStart,
      onSelectionUpdate: onSelectionUpdate,
      onSelectionEnd: onSelectionEnd,
    );
    final side = _WordSearchSidePanel(
      words: words,
      found: found,
      progress: progress,
      onNewGame: onNewGame,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showName) ...[
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Seu nome'),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
          ),
          const SizedBox(height: 14),
        ],
        Text(
          'Encontre as palavras na horizontal, vertical e diagonal.',
          style: TextStyle(color: palette.muted),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 820;
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  board,
                  const SizedBox(height: 18),
                  side,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: board),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: side),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _WordSearchSidePanel extends StatelessWidget {
  const _WordSearchSidePanel({
    required this.words,
    required this.found,
    required this.progress,
    required this.onNewGame,
  });

  final List<String> words;
  final Set<String> found;
  final double progress;
  final VoidCallback onNewGame;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.card.withValues(alpha: .72),
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Palavras',
                    style: TextStyle(
                      color: palette.foreground,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${found.length}/${words.length}',
                  style: TextStyle(
                    color: palette.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final word in words)
                  Chip(
                    avatar: Icon(
                      found.contains(word) ? Icons.check_circle : Icons.search,
                      size: 18,
                      color:
                          found.contains(word) ? Colors.green : palette.primary,
                    ),
                    label: Text(
                      word,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        decoration: found.contains(word)
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onNewGame,
              icon: const Icon(Icons.shuffle),
              label: const Text('Novo sorteio'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WordSearchBoard extends StatelessWidget {
  const _WordSearchBoard({
    required this.puzzle,
    required this.foundCells,
    required this.selectedCells,
    required this.onSelectionStart,
    required this.onSelectionUpdate,
    required this.onSelectionEnd,
  });

  final _WordPuzzle puzzle;
  final Set<int> foundCells;
  final List<int> selectedCells;
  final ValueChanged<int> onSelectionStart;
  final ValueChanged<int> onSelectionUpdate;
  final Future<void> Function() onSelectionEnd;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final selected = selectedCells.toSet();
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = min(constraints.maxWidth, 560.0);
        final boardPadding = boardSize < 380 ? 4.0 : 6.0;
        final gap = boardSize < 380 ? 1.5 : 3.0;
        final gridSize = boardSize - boardPadding * 2;
        final cellSize = (gridSize - gap * (puzzle.size - 1)) / puzzle.size;
        int? indexFromOffset(Offset localPosition) {
          final x = localPosition.dx - boardPadding;
          final y = localPosition.dy - boardPadding;
          if (x < 0 || y < 0 || x > gridSize || y > gridSize) return null;
          final col = (x / (cellSize + gap)).floor();
          final row = (y / (cellSize + gap)).floor();
          if (row < 0 || row >= puzzle.size || col < 0 || col >= puzzle.size) {
            return null;
          }
          return row * puzzle.size + col;
        }

        return Center(
          child: GestureDetector(
            onPanStart: (details) {
              final index = indexFromOffset(details.localPosition);
              if (index != null) onSelectionStart(index);
            },
            onPanUpdate: (details) {
              final index = indexFromOffset(details.localPosition);
              if (index != null) onSelectionUpdate(index);
            },
            onPanEnd: (_) => onSelectionEnd(),
            onTapDown: (details) {
              final index = indexFromOffset(details.localPosition);
              if (index != null) onSelectionStart(index);
            },
            onTapUp: (_) => onSelectionEnd(),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: boardSize,
              height: boardSize,
              padding: EdgeInsets.all(boardPadding),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .72),
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: palette.primary.withValues(alpha: .22)),
                boxShadow: [
                  BoxShadow(
                    color: palette.primary.withValues(alpha: .10),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: puzzle.size,
                  mainAxisSpacing: gap,
                  crossAxisSpacing: gap,
                ),
                itemCount: puzzle.size * puzzle.size,
                itemBuilder: (context, index) {
                  final row = index ~/ puzzle.size;
                  final col = index % puzzle.size;
                  final isFound = foundCells.contains(index);
                  final isSelected = selected.contains(index);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isFound
                          ? Colors.green.withValues(alpha: .20)
                          : isSelected
                              ? palette.primary.withValues(alpha: .24)
                              : palette.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isFound
                            ? Colors.green
                            : isSelected
                                ? palette.primary
                                : palette.border,
                      ),
                    ),
                    child: Text(
                      puzzle.letters[row][col],
                      style: TextStyle(
                        color: isFound
                            ? Colors.green.shade800
                            : palette.foreground,
                        fontSize: (cellSize * .54).clamp(12, 22).toDouble(),
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

typedef _MiniGameBuilder = Widget Function(
  MiniGameConfig config,
  _MiniGameCommon common,
);

class _MiniGameCommon {
  const _MiniGameCommon({
    required this.repository,
    required this.toast,
    required this.auth,
    required this.onBack,
  });

  final FamilyRepository repository;
  final ToastController toast;
  final AuthController auth;
  final VoidCallback onBack;
}

class _MiniGameRoute extends StatelessWidget {
  const _MiniGameRoute({
    super.key,
    required this.type,
    required this.repository,
    required this.toast,
    required this.auth,
    required this.onBack,
    required this.builder,
  });

  final String type;
  final FamilyRepository repository;
  final ToastController toast;
  final AuthController auth;
  final VoidCallback onBack;
  final _MiniGameBuilder builder;

  @override
  Widget build(BuildContext context) {
    return AppFixedHeaderScrollView(
      onRefresh: () async => invalidateQueries(context, QueryKeys.miniGames()),
      header: _GamePlayHeader(
        title: _miniGameTypeLabel(type),
        subtitle: 'Mini jogo configurável pelo painel.',
        icon: _miniGameIcon(type),
        onBack: onBack,
      ),
      headerGap: 14,
      children: [
        _GamePanel(
          child: AppQuery<List<MiniGameConfig>>(
            queryKey: QueryKeys.miniGames(),
            queryFn: repository.listMiniGames,
            loading: const SkeletonBox(height: 280, borderRadius: 8),
            builder: (context, configs, _) {
              MiniGameConfig? config;
              for (final row in configs) {
                if (row.type == type) {
                  config = row;
                  break;
                }
              }
              if (config == null) {
                return const _GameEmptyState(
                  text: 'Mini jogo inativo ou sem configuração.',
                );
              }
              return builder(
                config,
                _MiniGameCommon(
                  repository: repository,
                  toast: toast,
                  auth: auth,
                  onBack: onBack,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PlayerNameField extends StatelessWidget {
  const _PlayerNameField({required this.controller, required this.show});

  final TextEditingController controller;
  final bool show;

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(labelText: 'Seu nome'),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => FocusScope.of(context).unfocus(),
      ),
    );
  }
}

class _MemoryMatchGame extends StatefulWidget {
  const _MemoryMatchGame({required this.config, required this.common});

  final MiniGameConfig config;
  final _MiniGameCommon common;

  @override
  State<_MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends State<_MemoryMatchGame> {
  final name = TextEditingController();
  late List<_MemoryCardData> cards;
  final selected = <int>[];
  final matched = <int>{};
  bool checking = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  void _reset() {
    final labels = (widget.config.items.isEmpty
            ? ['Amor', 'Templo', 'Rudy', 'Shopping', 'Filme', 'Fernando']
            : widget.config.items)
        .take(8)
        .toList();
    cards = [
      for (final label in labels) ...[
        _MemoryCardData(label),
        _MemoryCardData(label),
      ],
    ]..shuffle(Random());
    selected.clear();
    matched.clear();
    checking = false;
  }

  Future<void> _tap(int index) async {
    if (checking || selected.contains(index) || matched.contains(index)) return;
    setState(() => selected.add(index));
    if (selected.length < 2) return;
    checking = true;
    final first = selected[0];
    final second = selected[1];
    if (cards[first].label == cards[second].label) {
      setState(() {
        matched.addAll([first, second]);
        selected.clear();
        checking = false;
      });
      if (matched.length == cards.length) {
        await _completeMiniGame(
          common: widget.common,
          game: widget.config.type,
          name: name.text,
          score: matched.length ~/ 2,
          total: cards.length ~/ 2,
        );
      }
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() {
      selected.clear();
      checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MiniGameIntro(config: widget.config),
        _PlayerNameField(
          controller: name,
          show: widget.common.auth.user == null,
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 700 ? 4 : 3;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: columns == 4 ? 1.35 : 1.08,
              ),
              itemBuilder: (context, index) {
                final visible =
                    selected.contains(index) || matched.contains(index);
                return InkWell(
                  onTap: () => _tap(index),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: visible
                          ? palette.primary.withValues(alpha: .16)
                          : palette.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: visible ? palette.primary : palette.border,
                      ),
                    ),
                    child: Text(
                      visible ? cards[index].label : '?',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.foreground,
                        fontSize: visible ? 15 : 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () => setState(_reset),
          icon: const Icon(Icons.shuffle),
          label: const Text('Recomeçar'),
        ),
      ],
    );
  }
}

class _MemoryCardData {
  const _MemoryCardData(this.label);
  final String label;
}

class _LoveOrderGame extends StatefulWidget {
  const _LoveOrderGame({required this.config, required this.common});

  final MiniGameConfig config;
  final _MiniGameCommon common;

  @override
  State<_LoveOrderGame> createState() => _LoveOrderGameState();
}

class _LoveOrderGameState extends State<_LoveOrderGame> {
  final name = TextEditingController();
  late List<String> shuffled;
  final picked = <String>[];

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  void _reset() {
    shuffled = [..._orderItems]..shuffle(Random());
    picked.clear();
  }

  List<String> get _orderItems {
    final items = widget.config.items.isEmpty
        ? ['Mutual', 'Primeiro encontro', 'Namoro', 'Casamento', 'Fernando']
        : widget.config.items;
    return items.take(8).toList();
  }

  Future<void> _pick(String item) async {
    if (picked.contains(item)) return;
    final expected = _orderItems[picked.length];
    if (item != expected) {
      widget.common.toast.error('Quase! Esse momento vem depois.');
      return;
    }
    setState(() => picked.add(item));
    if (picked.length == _orderItems.length) {
      await _completeMiniGame(
        common: widget.common,
        game: widget.config.type,
        name: name.text,
        score: picked.length,
        total: _orderItems.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MiniGameIntro(config: widget.config),
        _PlayerNameField(
          controller: name,
          show: widget.common.auth.user == null,
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final item in shuffled)
              ChoiceChip(
                selected: picked.contains(item),
                label: Text(item),
                onSelected: (_) => _pick(item),
              ),
          ],
        ),
        const SizedBox(height: 18),
        DecoratedBox(
          decoration: BoxDecoration(
            color: palette.card.withValues(alpha: .72),
            border: Border.all(color: palette.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              picked.isEmpty
                  ? 'Comece pelo primeiro momento.'
                  : picked.join('  >  '),
              style: TextStyle(
                color: palette.foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () => setState(_reset),
          icon: const Icon(Icons.replay),
          label: const Text('Recomeçar'),
        ),
      ],
    );
  }
}

class _ThisOrThatGame extends StatefulWidget {
  const _ThisOrThatGame({required this.config, required this.common});

  final MiniGameConfig config;
  final _MiniGameCommon common;

  @override
  State<_ThisOrThatGame> createState() => _ThisOrThatGameState();
}

class _ThisOrThatGameState extends State<_ThisOrThatGame> {
  final name = TextEditingController();
  int index = 0;
  int choices = 0;

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  List<List<String>> get rounds {
    final raw = widget.config.items.isEmpty
        ? [
            'Shopping|Filme no sofá',
            'Pizza|Hambúrguer',
            'Passeio|Casa juntinhos',
            'Doce|Salgado',
          ]
        : widget.config.items;
    return raw
        .map((item) => item.split('|').map((part) => part.trim()).toList())
        .where((parts) => parts.length >= 2 && parts[0].isNotEmpty)
        .map((parts) => [parts[0], parts[1]])
        .toList();
  }

  Future<void> _choose() async {
    final next = index + 1;
    setState(() {
      choices++;
      index = next;
    });
    if (next >= rounds.length) {
      await _completeMiniGame(
        common: widget.common,
        game: widget.config.type,
        name: name.text,
        score: next,
        total: rounds.length,
      );
    }
  }

  void _restart() {
    setState(() {
      index = 0;
      choices = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (rounds.isEmpty) {
      return const _GameEmptyState(
        text: 'Cadastre opções no formato "Opção A|Opção B".',
      );
    }
    final finished = index >= rounds.length;
    final current = finished ? rounds.last : rounds[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MiniGameIntro(config: widget.config),
        _PlayerNameField(
          controller: name,
          show: widget.common.auth.user == null,
        ),
        LinearProgressIndicator(
          value: finished ? 1 : (index + 1) / rounds.length,
          minHeight: 8,
          borderRadius: BorderRadius.circular(999),
        ),
        const SizedBox(height: 18),
        if (finished)
          _QuizFinished(
            score: choices,
            total: rounds.length,
            onRestart: _restart,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 620;
              final buttons = [
                for (final option in current)
                  FilledButton(
                    onPressed: _choose,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(option, textAlign: TextAlign.center),
                    ),
                  ),
              ];
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buttons[0],
                    const SizedBox(height: 10),
                    buttons[1],
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: buttons[0]),
                  const SizedBox(width: 12),
                  Expanded(child: buttons[1]),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _MiniGameIntro extends StatelessWidget {
  const _MiniGameIntro({required this.config});

  final MiniGameConfig config;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            config.title,
            style: TextStyle(
              color: palette.foreground,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (config.instructions.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(config.instructions, style: TextStyle(color: palette.muted)),
          ],
        ],
      ),
    );
  }
}

Future<void> _completeMiniGame({
  required _MiniGameCommon common,
  required String game,
  required String name,
  required int score,
  required int total,
}) async {
  await common.repository.completeGame(
    game: game,
    playerName: name,
    score: score,
    total: total,
  );
  common.toast.backendSuccess(common.repository.takeMessage());
}

class _GamePlayHeader extends StatelessWidget {
  const _GamePlayHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return AppPageHeader(
      title: title,
      subtitle: subtitle,
      icon: icon,
      onBack: onBack,
    );
  }
}

class _GamePanel extends StatelessWidget {
  const _GamePanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 520;
    return LovePanel(
      padding: EdgeInsets.all(compact ? 12 : 22),
      child: child,
    );
  }
}

class _GameEmptyState extends StatelessWidget {
  const _GameEmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Column(
      children: [
        Icon(Icons.info_outline, color: palette.primary, size: 42),
        const SizedBox(height: 10),
        Text(text, textAlign: TextAlign.center),
      ],
    );
  }
}

class _QuizFinished extends StatelessWidget {
  const _QuizFinished({
    required this.score,
    required this.total,
    required this.onRestart,
  });

  final int score;
  final int total;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Column(
      children: [
        Icon(Icons.celebration, size: 54, color: palette.primary),
        const SizedBox(height: 12),
        Text('Você acertou $score de $total.',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: onRestart,
          icon: const Icon(Icons.replay),
          label: const Text('Jogar novamente'),
        ),
      ],
    );
  }
}

List<String> _randomWords(List<GameWord> gameWords) {
  final all = gameWords
      .where((word) => word.active && word.word.trim().isNotEmpty)
      .map((word) => _normalizeWord(word.word))
      .where((word) => word.length >= 3 && word.length <= _wordSearchSize)
      .toList();
  if (all.isEmpty) {
    all.addAll([
      'FERNANDO',
      'MIRIAM',
      'FAMILIA',
      'AMOR',
      'TEMPLO',
      'FE',
      'LAR',
      'ETERNOS',
      'CARINHO',
      'FILHO',
      'JESUS',
      'ALIANCA',
    ]);
  }
  all.shuffle(Random());
  return all.toSet().take(8).toList();
}

const _wordSearchSize = 12;

class _WordPuzzle {
  const _WordPuzzle({required this.size, required this.letters});

  final int size;
  final List<List<String>> letters;

  factory _WordPuzzle.empty() => _WordPuzzle(
        size: _wordSearchSize,
        letters: List.generate(
          _wordSearchSize,
          (_) => List.generate(_wordSearchSize, (_) => ''),
        ),
      );
}

class _WordDirection {
  const _WordDirection(this.row, this.col);

  final int row;
  final int col;
}

final _wordDirections = [
  const _WordDirection(0, 1),
  const _WordDirection(1, 0),
  const _WordDirection(1, 1),
  const _WordDirection(-1, 1),
  const _WordDirection(0, -1),
  const _WordDirection(-1, 0),
  const _WordDirection(-1, -1),
  const _WordDirection(1, -1),
];

_WordPuzzle _generateWordPuzzle(List<String> words) {
  final random = Random();
  final board = List.generate(
    _wordSearchSize,
    (_) => List.generate(_wordSearchSize, (_) => ''),
  );
  final sortedWords = [...words]..sort((a, b) => b.length.compareTo(a.length));
  for (final word in sortedWords) {
    _placeWord(board, word, random);
  }
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  for (var row = 0; row < _wordSearchSize; row++) {
    for (var col = 0; col < _wordSearchSize; col++) {
      if (board[row][col].isEmpty) {
        board[row][col] = alphabet[random.nextInt(alphabet.length)];
      }
    }
  }
  return _WordPuzzle(size: _wordSearchSize, letters: board);
}

bool _placeWord(List<List<String>> board, String word, Random random) {
  for (var attempt = 0; attempt < 180; attempt++) {
    final direction = _wordDirections[random.nextInt(_wordDirections.length)];
    final row = random.nextInt(_wordSearchSize);
    final col = random.nextInt(_wordSearchSize);
    if (!_canPlaceWord(board, word, row, col, direction)) continue;
    for (var i = 0; i < word.length; i++) {
      board[row + direction.row * i][col + direction.col * i] = word[i];
    }
    return true;
  }
  return false;
}

bool _canPlaceWord(
  List<List<String>> board,
  String word,
  int row,
  int col,
  _WordDirection direction,
) {
  final endRow = row + direction.row * (word.length - 1);
  final endCol = col + direction.col * (word.length - 1);
  if (endRow < 0 ||
      endRow >= _wordSearchSize ||
      endCol < 0 ||
      endCol >= _wordSearchSize) {
    return false;
  }
  for (var i = 0; i < word.length; i++) {
    final current = board[row + direction.row * i][col + direction.col * i];
    if (current.isNotEmpty && current != word[i]) return false;
  }
  return true;
}

List<int> _linePath(int start, int end, int size) {
  final startRow = start ~/ size;
  final startCol = start % size;
  final endRow = end ~/ size;
  final endCol = end % size;
  final rowDelta = endRow - startRow;
  final colDelta = endCol - startCol;
  final rowStep = rowDelta == 0 ? 0 : rowDelta.sign;
  final colStep = colDelta == 0 ? 0 : colDelta.sign;
  if (rowDelta != 0 && colDelta != 0 && rowDelta.abs() != colDelta.abs()) {
    return const [];
  }
  if (rowDelta == 0 && colDelta == 0) return [start];
  final length = max(rowDelta.abs(), colDelta.abs()) + 1;
  return List.generate(
    length,
    (i) => (startRow + rowStep * i) * size + startCol + colStep * i,
  );
}

String _normalizeWord(String value) {
  return value
      .trim()
      .toUpperCase()
      .replaceAll(RegExp(r'[ÁÀÂÃÄ]'), 'A')
      .replaceAll(RegExp(r'[ÉÈÊË]'), 'E')
      .replaceAll(RegExp(r'[ÍÌÎÏ]'), 'I')
      .replaceAll(RegExp(r'[ÓÒÔÕÖ]'), 'O')
      .replaceAll(RegExp(r'[ÚÙÛÜ]'), 'U')
      .replaceAll('Ç', 'C')
      .replaceAll(RegExp(r'[^A-Z]'), '');
}

_GameView _viewForMiniGame(String type) {
  return switch (type) {
    'memory_match' => _GameView.memoryMatch,
    'love_order' => _GameView.loveOrder,
    'this_or_that' => _GameView.thisOrThat,
    _ => _GameView.memoryMatch,
  };
}

IconData _miniGameIcon(String type) {
  return switch (type) {
    'memory_match' => Icons.style_outlined,
    'love_order' => Icons.timeline_outlined,
    'this_or_that' => Icons.compare_arrows_outlined,
    _ => Icons.extension_outlined,
  };
}

String _miniGameTypeLabel(String type) {
  return switch (type) {
    'memory_match' => 'Memória da Família',
    'love_order' => 'Linha do Amor',
    'this_or_that' => 'Isso ou Aquilo',
    _ => 'Mini jogo',
  };
}

String _miniGameMetric(MiniGameConfig config) {
  return switch (config.type) {
    'memory_match' => '${min(config.items.length, 8)} pares',
    'love_order' => '${min(config.items.length, 8)} passos',
    'this_or_that' => '${config.items.length} rodadas',
    _ => '${config.items.length} itens',
  };
}
