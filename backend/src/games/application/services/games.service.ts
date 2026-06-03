import { Injectable } from '@nestjs/common';
import type { UserEntity } from '@auth/domain/entities/user.entity';
import {
  GamesRepository,
  GameWordWrite,
  QuizQuestionWrite,
} from '../../infrastructure/repositories/games.repository';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import {
  gameCompletionFactory,
  gameWordFactory,
  quizQuestionFactory,
} from '../factories/game.factory';
import {
  gameCompletionMapper,
  gameStatMapper,
  gameWordMapper,
  quizQuestionMapper,
} from '../mappers/game.mapper';
import type {
  GameCompletionWriteDto,
  GameStatResponseDto,
  GameWordWriteDto,
  QuizQuestionWriteDto,
} from '../../interfaces/dto/game.dto';

@Injectable()
export class GamesService {
  constructor(private games: GamesRepository) {}

  async quizPublic(query?: PaginationQuery) {
    const result = await this.games.listQuestions(false, query);
    return {
      ...result,
      items: result.items.map((item) => quizQuestionMapper.toDto(item)),
    };
  }

  async quizAdmin(query?: PaginationQuery) {
    const result = await this.games.listQuestions(true, query);
    return {
      ...result,
      items: result.items.map((item) => quizQuestionMapper.toDto(item)),
    };
  }

  async createQuestion(data: QuizQuestionWriteDto) {
    return quizQuestionMapper.toDto(
      await this.games.createQuestion(
        this.normalizeQuestion(data) as QuizQuestionWrite,
      ),
    );
  }

  async updateQuestion(id: string, data: Partial<QuizQuestionWriteDto>) {
    const row = await this.games.updateQuestion(
      id,
      quizQuestionFactory.create(data),
    );
    return row ? quizQuestionMapper.toDto(row) : null;
  }

  deleteQuestion(id: string) {
    return this.games.deleteQuestion(id);
  }

  async wordsPublic(query?: PaginationQuery) {
    const result = await this.games.listWords(false, query);
    return {
      ...result,
      items: result.items.map((item) => gameWordMapper.toDto(item)),
    };
  }

  async wordsAdmin(query?: PaginationQuery) {
    const result = await this.games.listWords(true, query);
    return {
      ...result,
      items: result.items.map((item) => gameWordMapper.toDto(item)),
    };
  }

  async createWord(data: GameWordWriteDto) {
    return gameWordMapper.toDto(
      await this.games.createWord(this.normalizeWord(data) as GameWordWrite),
    );
  }

  async updateWord(id: string, data: Partial<GameWordWriteDto>) {
    const row = await this.games.updateWord(id, gameWordFactory.create(data));
    return row ? gameWordMapper.toDto(row) : null;
  }

  deleteWord(id: string) {
    return this.games.deleteWord(id);
  }

  complete(body: GameCompletionWriteDto, user?: UserEntity | null) {
    const playerName =
      user?.name || user?.email || body.playerName?.trim() || 'Visitante';
    return this.games
      .createCompletion(
        gameCompletionFactory.create({
          ...body,
          playerName,
          userId: user?.id ?? null,
        }),
      )
      .then((row) => gameCompletionMapper.toDto(row));
  }

  async stats(query?: PaginationQuery) {
    const result = await this.games.stats(query);
    return {
      ...result,
      items: result.items.map((item) =>
        gameStatMapper.toDto(item as GameStatResponseDto),
      ),
    };
  }

  private normalizeQuestion(data: Partial<QuizQuestionWriteDto>) {
    const normalized = quizQuestionFactory.create(data);
    return {
      ...normalized,
      active: normalized.active ?? true,
    };
  }

  private normalizeWord(data: Partial<GameWordWriteDto>) {
    const normalized = gameWordFactory.create(data);
    return {
      ...normalized,
      active: normalized.active ?? true,
    };
  }
}
