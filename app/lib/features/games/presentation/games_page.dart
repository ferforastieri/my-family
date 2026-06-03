import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
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
  List<QuizQuestion> questions = [];
  int index = 0;
  int score = 0;
  bool loading = true;
  bool finished = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      index = 0;
      score = 0;
      finished = false;
    });
    try {
      questions = await widget.repository.listQuizQuestions();
    } catch (error) {
      widget.toast.error(error.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _answer(int selected) async {
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
    widget.toast.success('Quiz concluído!');
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
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
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : questions.isEmpty
                            ? const _GameEmptyState(
                                text: 'Nenhuma pergunta ativa no momento.')
                            : finished
                                ? _QuizFinished(
                                    score: score,
                                    total: questions.length,
                                    onRestart: () => setState(() {
                                      index = 0;
                                      score = 0;
                                      finished = false;
                                    }),
                                  )
                                : _QuizQuestionView(
                                    question: questions[index],
                                    index: index,
                                    total: questions.length,
                                    name: name,
                                    showName: widget.auth.user == null,
                                    onAnswer: _answer,
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
  late List<String> grid;
  final Set<String> found = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    words = [];
    grid = [];
    _load();
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      gameWords = await widget.repository.listGameWords();
      _newGame();
    } catch (error) {
      widget.toast.error(error.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _newGame() {
    words = _randomWords(gameWords);
    grid = _wordGrid(words);
    found.clear();
  }

  Future<void> _toggle(String word) async {
    setState(() => found.add(word));
    if (found.length == words.length) {
      await widget.repository.completeGame(
        game: 'word_search',
        playerName: name.text,
        score: found.length,
        total: words.length,
      );
      widget.toast.success('Caça palavras concluído!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return RefreshIndicator(
      onRefresh: _load,
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
                    subtitle: 'Toque nas palavras escondidas.',
                    icon: Icons.grid_on_outlined,
                    onBack: widget.onBack,
                  ),
                  const SizedBox(height: 14),
                  _GamePanel(
                    child: loading
                        ? const SkeletonBox(height: 320, borderRadius: 8)
                        : Column(
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
                              Text('Encontre as palavras tocando nelas.',
                                  style: TextStyle(color: palette.muted)),
                              const SizedBox(height: 18),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  for (final token in grid)
                                    FilterChip(
                                      selected: found.contains(token),
                                      label: Text(token),
                                      onSelected: words.contains(token) &&
                                              !found.contains(token)
                                          ? (_) => _toggle(token)
                                          : null,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              LinearProgressIndicator(
                                value: words.isEmpty
                                    ? 0
                                    : found.length / words.length,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                  'Encontradas: ${found.length}/${words.length}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900)),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () => setState(_newGame),
                                icon: const Icon(Icons.shuffle),
                                label: const Text('Novo sorteio'),
                              ),
                            ],
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
      .map((word) => word.word.trim().toUpperCase())
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
  return all.take(6).toList();
}

List<String> _wordGrid(List<String> words) {
  final fillers = [
    'CASA',
    'ROSA',
    'LUZ',
    'VIDA',
    'PAZ',
    'CEU',
    'DIA',
    'SORRISO',
    'ABRACO',
    'DOCE',
    'SONHO',
    'JARDIM',
  ]..shuffle(Random());
  return [...words, ...fillers.take(10)]..shuffle(Random());
}
