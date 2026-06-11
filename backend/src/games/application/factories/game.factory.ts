import type { Factory } from '@shared/application/mapper';
import type {
  GameCompletionWrite,
  GameWordWrite,
  MiniGameConfigWrite,
  QuizQuestionWrite,
} from '../../infrastructure/repositories/games.repository';
import type {
  GameCompletionWriteDto,
  GameWordWriteDto,
  MiniGameConfigWriteDto,
  QuizQuestionWriteDto,
} from '../../interfaces/dto/game.dto';

export class QuizQuestionFactory implements Factory<
  Partial<QuizQuestionWriteDto>,
  Partial<QuizQuestionWrite>
> {
  create(input: Partial<QuizQuestionWriteDto>): Partial<QuizQuestionWrite> {
    return {
      question: input.question?.trim(),
      options: input.options?.map((option) => option.trim()).filter(Boolean),
      correctIndex:
        input.correctIndex == null ? undefined : Number(input.correctIndex),
      active: input.active,
    };
  }
}

export class GameWordFactory implements Factory<
  Partial<GameWordWriteDto>,
  Partial<GameWordWrite>
> {
  create(input: Partial<GameWordWriteDto>): Partial<GameWordWrite> {
    return {
      word:
        input.word == null
          ? undefined
          : input.word
              .normalize('NFD')
              .replace(/[\u0300-\u036f]/g, '')
              .replace(/[^a-zA-Z]/g, '')
              .toUpperCase(),
      active: input.active,
    };
  }
}

export class GameCompletionFactory implements Factory<
  GameCompletionWriteDto & { userId?: string | null; playerName: string },
  GameCompletionWrite
> {
  create(
    input: GameCompletionWriteDto & {
      userId?: string | null;
      playerName: string;
    },
  ): GameCompletionWrite {
    return {
      game: input.game,
      playerName: input.playerName,
      userId: input.userId ?? null,
      score: input.score ?? null,
      total: input.total ?? null,
    };
  }
}

export class MiniGameConfigFactory implements Factory<
  Partial<MiniGameConfigWriteDto>,
  Partial<MiniGameConfigWrite>
> {
  create(input: Partial<MiniGameConfigWriteDto>): Partial<MiniGameConfigWrite> {
    return {
      type: input.type,
      title: input.title?.trim(),
      instructions: input.instructions?.trim(),
      items: input.items?.map((item) => item.trim()).filter(Boolean),
      active: input.active,
    };
  }
}

export const quizQuestionFactory = new QuizQuestionFactory();
export const gameWordFactory = new GameWordFactory();
export const gameCompletionFactory = new GameCompletionFactory();
export const miniGameConfigFactory = new MiniGameConfigFactory();
