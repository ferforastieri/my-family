import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/api/query_keys.dart';
import '../../../core/query/app_query.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/love_action_card.dart';
import '../../../core/widgets/love_background.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../data/family_repository.dart';
import '../../../data/models.dart';

enum _GameView { hub, quiz, wordSearch }

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
];

class _GamesHub extends StatelessWidget {
  const _GamesHub({super.key, required this.onOpen});

  final ValueChanged<_GameView> onOpen;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 112),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _GamesHero(),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 820;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: wide ? 2 : 1,
                        childAspectRatio: wide ? 1.55 : 1.38,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        children: [
                          _GameCard(
                            icon: Icons.favorite,
                            title: 'Quiz do Amor',
                            body:
                                'Perguntas dinâmicas para testar carinho, memória e pequenos detalhes da família.',
                            color: palette.primary,
                            footer: 'Perguntas editáveis pelo admin',
                            onTap: () => onOpen(_GameView.quiz),
                          ),
                          _GameCard(
                            icon: Icons.grid_on,
                            title: 'Caça Palavras',
                            body:
                                'Palavras familiares e românticas sorteadas a cada partida.',
                            color: palette.primaryDark,
                            footer: 'Sorteio novo a cada rodada',
                            onTap: () => onOpen(_GameView.wordSearch),
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
    required this.footer,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final String footer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: LoveActionCard(
            title: title,
            description: body,
            icon: icon,
            onTap: onTap,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 56),
          ),
        ),
        Positioned(
          left: 20,
          right: 16,
          bottom: 14,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  footer,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ],
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
    return RefreshIndicator(
      onRefresh: () async =>
          invalidateQueries(context, QueryKeys.quizQuestions()),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 112),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GamePlayHeader(
                    title: 'Quiz do Amor',
                    subtitle: 'Responda uma pergunta por vez.',
                    icon: Icons.favorite_outline,
                    onBack: widget.onBack,
                  ),
                  const SizedBox(height: 14),
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
                                onAnswer: (selected) =>
                                    _answer(questions, selected),
                              );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
        for (var i = 0; i < question.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton.icon(
              onPressed: () => onAnswer(i),
              icon: Icon(Icons.favorite_border, color: palette.primary),
              label: Align(
                alignment: Alignment.centerLeft,
                child: Text(question.options[i]),
              ),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
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
    final palette = Theme.of(context).extension<AppPalette>()!;
    return RefreshIndicator(
      onRefresh: () async =>
          invalidateQueries(context, QueryKeys.wordSearchWords()),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 112),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GamePlayHeader(
                    title: 'Caça Palavras',
                    subtitle:
                        'Arraste sobre as letras para formar cada palavra.',
                    icon: Icons.grid_on_outlined,
                    onBack: widget.onBack,
                  ),
                  const SizedBox(height: 14),
                  _GamePanel(
                    child: AppQuery<List<GameWord>>(
                      queryKey: QueryKeys.wordSearchWords(),
                      queryFn: widget.repository.listGameWords,
                      loading: const SkeletonBox(height: 320, borderRadius: 8),
                      builder: (context, remoteWords, _) {
                        if (_wordsChanged(remoteWords) || words.isEmpty) {
                          _newGame(remoteWords);
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (widget.auth.user == null) ...[
                              TextField(
                                controller: name,
                                decoration: const InputDecoration(
                                    labelText: 'Seu nome'),
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) =>
                                    FocusScope.of(context).unfocus(),
                              ),
                              const SizedBox(height: 14),
                            ],
                            Text(
                                'Encontre as palavras na horizontal, vertical e diagonal.',
                                style: TextStyle(color: palette.muted)),
                            const SizedBox(height: 18),
                            _WordSearchBoard(
                              puzzle: puzzle,
                              foundCells: foundCells,
                              selectedCells: selectedCells,
                              onSelectionStart: _startSelection,
                              onSelectionUpdate: _updateSelection,
                              onSelectionEnd: _endSelection,
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final word in words)
                                  Chip(
                                    avatar: Icon(
                                      found.contains(word)
                                          ? Icons.check_circle
                                          : Icons.search,
                                      size: 18,
                                      color: found.contains(word)
                                          ? Colors.green
                                          : palette.primary,
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
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: words.isEmpty
                                  ? 0
                                  : found.length / words.length,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            const SizedBox(height: 10),
                            Text('Encontradas: ${found.length}/${words.length}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900)),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () => setState(_newGame),
                              icon: const Icon(Icons.shuffle),
                              label: const Text('Novo sorteio'),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
        final cellSize = boardSize / puzzle.size;
        int? indexFromOffset(Offset localPosition) {
          final col = (localPosition.dx / cellSize).floor();
          final row = (localPosition.dy / cellSize).floor();
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
            child: Container(
              width: boardSize,
              height: boardSize,
              padding: const EdgeInsets.all(6),
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
                  mainAxisSpacing: 3,
                  crossAxisSpacing: 3,
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
                        fontSize: cellSize.clamp(18, 28).toDouble(),
                        fontWeight: FontWeight.w900,
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
    return LovePanel(
      padding: const EdgeInsets.all(22),
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
