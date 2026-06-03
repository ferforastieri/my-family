import { Injectable } from '@nestjs/common';
import type { UserEntity } from '@shared/domain/entities';
import {
  GamesRepository,
  GameWordWrite,
  QuizQuestionWrite,
} from '../infrastructure/repositories/games.repository';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';

@Injectable()
export class GamesService {
  constructor(private games: GamesRepository) {}

  quizPublic(query?: PaginationQuery) {
    return this.games.listQuestions(false, query);
  }

  quizAdmin(query?: PaginationQuery) {
    return this.games.listQuestions(true, query);
  }

  createQuestion(data: QuizQuestionWrite) {
    return this.games.createQuestion(this.normalizeQuestion(data));
  }

  updateQuestion(id: string, data: Partial<QuizQuestionWrite>) {
    return this.games.updateQuestion(id, {
      ...data,
      question: data.question?.trim(),
      options: data.options?.map((option) => option.trim()).filter(Boolean),
      correctIndex:
        data.correctIndex == null ? undefined : Number(data.correctIndex),
    });
  }

  deleteQuestion(id: string) {
    return this.games.deleteQuestion(id);
  }

  wordsPublic(query?: PaginationQuery) {
    return this.games.listWords(false, query);
  }

  wordsAdmin(query?: PaginationQuery) {
    return this.games.listWords(true, query);
  }

  createWord(data: GameWordWrite) {
    return this.games.createWord(this.normalizeWord(data));
  }

  updateWord(id: string, data: Partial<GameWordWrite>) {
    return this.games.updateWord(id, {
      ...data,
      word: data.word == null ? undefined : this.normalizeWordText(data.word),
    });
  }

  deleteWord(id: string) {
    return this.games.deleteWord(id);
  }

  complete(
    body: {
      game: 'quiz' | 'word_search';
      playerName?: string;
      score?: number;
      total?: number;
    },
    user?: UserEntity | null,
  ) {
    return this.games.createCompletion({
      game: body.game,
      playerName:
        user?.name || user?.email || body.playerName?.trim() || 'Visitante',
      userId: user?.id ?? null,
      score: body.score ?? null,
      total: body.total ?? null,
    });
  }

  stats(query?: PaginationQuery) {
    return this.games.stats(query);
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

  private normalizeWord(data: GameWordWrite) {
    return {
      word: this.normalizeWordText(data.word),
      active: data.active ?? true,
    };
  }

  private normalizeWordText(word: string) {
    return word
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[^a-zA-Z]/g, '')
      .toUpperCase();
  }
}
