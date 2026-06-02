import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/love_background.dart';
import '../../../core/widgets/love_text_card.dart';
import '../../../core/widgets/section_title.dart';
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
  List<QuizQuestion> questions = [];
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
      questions = await widget.repository.listQuizQuestionsAdmin();
      stats = await widget.repository.gameStats();
    } catch (error) {
      widget.toast.error(error.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoveBackground(
      child: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SectionTitle('Administração', size: 38),
          const SizedBox(height: 32),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                children: [
                  const LoveTextCard(
                      title: 'Usuários',
                      body:
                          'Gerenciamento via eventos users.* com permissão de admin.'),
                  const LoveTextCard(
                      title: 'Notificações',
                      body: 'Envio, agendamento e histórico via WebSocket.'),
                  _QuizAdminCard(
                    questions: questions,
                    loading: loading,
                    onAdd: () => _openQuestionSheet(),
                    onEdit: _openQuestionSheet,
                    onDelete: _deleteQuestion,
                  ),
                  _GameStatsCard(stats: stats, loading: loading),
                ],
              ),
            ),
          ),
        ],
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
}

class _QuizAdminCard extends StatelessWidget {
  const _QuizAdminCard({
    required this.questions,
    required this.loading,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<QuizQuestion> questions;
  final bool loading;
  final VoidCallback onAdd;
  final ValueChanged<QuizQuestion> onEdit;
  final ValueChanged<QuizQuestion> onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Perguntas do Quiz do Amor',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                ),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Pergunta'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (questions.isEmpty)
              const Text('Nenhuma pergunta cadastrada.')
            else
              for (final question in questions)
                ListTile(
                  title: Text(question.question),
                  subtitle: Text(question.active ? 'Ativa' : 'Inativa'),
                  trailing: Wrap(
                    children: [
                      IconButton(
                          onPressed: () => onEdit(question),
                          icon: const Icon(Icons.edit_outlined)),
                      IconButton(
                          onPressed: () => onDelete(question),
                          icon: const Icon(Icons.delete_outline)),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _GameStatsCard extends StatelessWidget {
  const _GameStatsCard({required this.stats, required this.loading});

  final List<GameStat> stats;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Conclusões dos Jogos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (stats.isEmpty)
              const Text('Nenhuma conclusão registrada ainda.')
            else
              for (final stat in stats)
                ListTile(
                  leading: Icon(stat.game == 'quiz'
                      ? Icons.favorite_outline
                      : Icons.grid_on_outlined),
                  title: Text(stat.playerName),
                  subtitle: Text(
                      stat.game == 'quiz' ? 'Quiz do Amor' : 'Caça Palavras'),
                  trailing: Text(
                    '${stat.count}x${stat.bestScore == null ? '' : ' • melhor ${stat.bestScore}'}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
          ],
        ),
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
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.question == null ? 'Nova pergunta' : 'Editar pergunta',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          TextField(
            controller: question,
            decoration: const InputDecoration(labelText: 'Pergunta'),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
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
          const SizedBox(height: 12),
          FilledButton(
            onPressed: saving ? null : _save,
            child: Text(saving ? 'Salvando...' : 'Salvar'),
          ),
        ],
      ),
    );
  }
}
