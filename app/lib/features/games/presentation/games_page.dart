import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/love_background.dart';
import '../../../core/widgets/section_title.dart';
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

  @override
  Widget build(BuildContext context) {
    return LoveBackground(
      child: switch (view) {
        _GameView.hub =>
          _GamesHub(onOpen: (next) => setState(() => view = next)),
        _GameView.quiz => _QuizGame(
            repository: widget.repository,
            toast: widget.toast,
            auth: widget.auth,
            onBack: () => setState(() => view = _GameView.hub),
          ),
        _GameView.wordSearch => _WordSearchGame(
            repository: widget.repository,
            toast: widget.toast,
            auth: widget.auth,
            onBack: () => setState(() => view = _GameView.hub),
          ),
      },
    );
  }
}

class _GamesHub extends StatelessWidget {
  const _GamesHub({required this.onOpen});

  final ValueChanged<_GameView> onOpen;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const SectionTitle('Jogos do Amor', size: 38),
        const SizedBox(height: 26),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Wrap(
              spacing: 18,
              runSpacing: 18,
              children: [
                _GameCard(
                  icon: Icons.favorite,
                  title: 'Quiz do Amor',
                  body: 'Perguntas dinâmicas que um admin pode mudar no banco.',
                  color: palette.primary,
                  onTap: () => onOpen(_GameView.quiz),
                ),
                _GameCard(
                  icon: Icons.grid_on,
                  title: 'Caça Palavras',
                  body:
                      'Palavras familiares e românticas sorteadas a cada partida.',
                  color: palette.primaryDark,
                  onTap: () => onOpen(_GameView.wordSearch),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return SizedBox(
      width: 470,
      child: Material(
        color: palette.card,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: color.withValues(alpha: .14),
                  foregroundColor: color,
                  child: Icon(icon, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text(body, style: TextStyle(color: palette.muted)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizGame extends StatefulWidget {
  const _QuizGame({
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
    final palette = Theme.of(context).extension<AppPalette>()!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _BackTitle(title: 'Quiz do Amor', onBack: widget.onBack),
        const SizedBox(height: 18),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: palette.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : questions.isEmpty
                        ? const Text('Nenhuma pergunta ativa no momento.')
                        : finished
                            ? Column(
                                children: [
                                  const Icon(Icons.celebration, size: 54),
                                  const SizedBox(height: 12),
                                  Text(
                                      'Você acertou $score de ${questions.length}.',
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 14),
                                  FilledButton(
                                    onPressed: () => setState(() {
                                      index = 0;
                                      score = 0;
                                      finished = false;
                                    }),
                                    child: const Text('Jogar novamente'),
                                  ),
                                ],
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
            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Pergunta ${index + 1} de $total',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Text(question.question,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 18),
        if (showName) ...[
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Seu nome'),
          ),
          const SizedBox(height: 12),
        ],
        for (var i = 0; i < question.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              onPressed: () => onAnswer(i),
              child: Text(question.options[i]),
            ),
          ),
      ],
    );
  }
}

class _WordSearchGame extends StatefulWidget {
  const _WordSearchGame({
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
  late List<String> words;
  late List<String> grid;
  final Set<String> found = {};

  @override
  void initState() {
    super.initState();
    words = _randomWords();
    grid = _wordGrid(words);
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
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
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _BackTitle(title: 'Caça Palavras', onBack: widget.onBack),
        const SizedBox(height: 18),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: palette.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.auth.user == null) ...[
                      TextField(
                        controller: name,
                        decoration:
                            const InputDecoration(labelText: 'Seu nome'),
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
                            onSelected:
                                words.contains(token) && !found.contains(token)
                                    ? (_) => _toggle(token)
                                    : null,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Encontradas: ${found.length}/${words.length}',
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => setState(() {
                        words = _randomWords();
                        grid = _wordGrid(words);
                        found.clear();
                      }),
                      child: const Text('Novo sorteio'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackTitle extends StatelessWidget {
  const _BackTitle({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
        Expanded(child: SectionTitle(title, size: 34)),
      ],
    );
  }
}

List<String> _randomWords() {
  final all = [
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
    'ALIanca'.toUpperCase(),
  ]..shuffle(Random());
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
