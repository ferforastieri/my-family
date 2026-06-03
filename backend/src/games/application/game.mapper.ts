import type { Mapper } from '@shared/application/mapper';
import type {
  GameCompletionEntity,
  GameWordEntity,
  QuizQuestionEntity,
} from '@shared/domain/entities';
import {
  GameCompletionResponseDto,
  GameStatResponseDto,
  GameWordResponseDto,
  QuizQuestionResponseDto,
} from '../interfaces/dto/game.dto';

export class QuizQuestionMapper implements Mapper<
  QuizQuestionEntity,
  QuizQuestionResponseDto
> {
  toDto(source: QuizQuestionEntity): QuizQuestionResponseDto {
    return {
      id: source.id,
      question: source.question,
      options: source.options,
      correctIndex: source.correctIndex,
      active: source.active,
      createdAt: source.createdAt,
      updatedAt: source.updatedAt,
    };
  }
}

export class GameWordMapper implements Mapper<
  GameWordEntity,
  GameWordResponseDto
> {
  toDto(source: GameWordEntity): GameWordResponseDto {
    return {
      id: source.id,
      word: source.word,
      active: source.active,
      createdAt: source.createdAt,
      updatedAt: source.updatedAt,
    };
  }
}

export class GameCompletionMapper implements Mapper<
  GameCompletionEntity,
  GameCompletionResponseDto
> {
  toDto(source: GameCompletionEntity): GameCompletionResponseDto {
    return {
      id: source.id,
      game: source.game,
      playerName: source.playerName,
      userId: source.userId ?? null,
      score: source.score ?? null,
      total: source.total ?? null,
      createdAt: source.createdAt,
    };
  }
}

export class GameStatMapper implements Mapper<
  GameStatResponseDto,
  GameStatResponseDto
> {
  toDto(source: GameStatResponseDto): GameStatResponseDto {
    return source;
  }
}

export const quizQuestionMapper = new QuizQuestionMapper();
export const gameWordMapper = new GameWordMapper();
export const gameCompletionMapper = new GameCompletionMapper();
export const gameStatMapper = new GameStatMapper();
