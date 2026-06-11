import {
  IsArray,
  IsBoolean,
  IsIn,
  IsNumber,
  IsOptional,
  IsString,
} from 'class-validator';

export const miniGameTypes = [
  'memory_match',
  'love_order',
  'this_or_that',
] as const;

export type MiniGameType = (typeof miniGameTypes)[number];

export class QuizQuestionWriteDto {
  @IsString()
  question: string;

  @IsArray()
  @IsString({ each: true })
  options: string[];

  @IsNumber()
  correctIndex: number;

  @IsOptional()
  @IsBoolean()
  active?: boolean;
}

export class GameWordWriteDto {
  @IsString()
  word: string;

  @IsOptional()
  @IsBoolean()
  active?: boolean;
}

export class GameCompletionWriteDto {
  @IsString()
  game: string;

  @IsOptional()
  @IsString()
  playerName?: string;

  @IsOptional()
  @IsNumber()
  score?: number;

  @IsOptional()
  @IsNumber()
  total?: number;
}

export class MiniGameConfigWriteDto {
  @IsIn(miniGameTypes)
  type: MiniGameType;

  @IsString()
  title: string;

  @IsOptional()
  @IsString()
  instructions?: string;

  @IsArray()
  @IsString({ each: true })
  items: string[];

  @IsOptional()
  @IsBoolean()
  active?: boolean;
}

export class QuizQuestionResponseDto {
  id: string;
  question: string;
  options: string[];
  correctIndex: number;
  active: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export class GameWordResponseDto {
  id: string;
  word: string;
  active: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export class GameCompletionResponseDto {
  id: string;
  game: string;
  playerName: string;
  userId: string | null;
  score: number | null;
  total: number | null;
  createdAt: Date;
}

export class GameStatResponseDto {
  game: string;
  playerName: string;
  count: number;
  bestScore: number | null;
  lastAt: number;
}

export class MiniGameConfigResponseDto {
  id: string;
  type: MiniGameType;
  title: string;
  instructions: string;
  items: string[];
  active: boolean;
  createdAt: Date;
  updatedAt: Date;
}
