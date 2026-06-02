import { Injectable } from '@nestjs/common';
import type { UserEntity } from '@shared/domain/entities';
import { GamesRepository, QuizQuestionWrite } from '../infrastructure/repositories/games.repository';

@Injectable()
export class GamesService {
  constructor(private games: GamesRepository) {}

  quizPublic() {
    return this.games.listQuestions(false);
  }

  quizAdmin() {
    return this.games.listQuestions(true);
  }

  createQuestion(data: QuizQuestionWrite) {
    return this.games.createQuestion(this.normalizeQuestion(data));
  }

  updateQuestion(id: string, data: Partial<QuizQuestionWrite>) {
    return this.games.updateQuestion(id, {
      ...data,
      question: data.question?.trim(),
      options: data.options?.map((option) => option.trim()).filter(Boolean),
      correctIndex: data.correctIndex == null ? undefined : Number(data.correctIndex),
    });
  }

  deleteQuestion(id: string) {
    return this.games.deleteQuestion(id);
  }

  complete(body: { game: 'quiz' | 'word_search'; playerName?: string; score?: number; total?: number }, user?: UserEntity | null) {
    return this.games.createCompletion({
      game: body.game,
      playerName: user?.name || user?.email || body.playerName?.trim() || 'Visitante',
      userId: user?.id ?? null,
      score: body.score ?? null,
      total: body.total ?? null,
    });
  }

  stats() {
    return this.games.stats();
  }

  private normalizeQuestion(data: QuizQuestionWrite) {
    return {
      ...data,
      question: data.question.trim(),
      options: data.options.map((option) => option.trim()).filter(Boolean),
      correctIndex: Number(data.correctIndex),
      active: data.active ?? true,
    };
  }
}
