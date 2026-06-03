import {
  IsArray,
  IsBoolean,
  IsIn,
  IsNumber,
  IsOptional,
  IsString,
} from 'class-validator';

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
  @IsIn(['quiz', 'word_search'])
  game: 'quiz' | 'word_search';

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
  game: 'quiz' | 'word_search';
  playerName: string;
  userId: string | null;
  score: number | null;
  total: number | null;
  createdAt: Date;
}

export class GameStatResponseDto {
  game: 'quiz' | 'word_search';
  playerName: string;
  count: number;
  bestScore: number | null;
  lastAt: number;
}
