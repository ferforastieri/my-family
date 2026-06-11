export interface QuizQuestionEntity {
  id: string;
  question: string;
  options: string[];
  correctIndex: number;
  active: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface GameCompletionEntity {
  id: string;
  game: string;
  playerName: string;
  userId?: string | null;
  score?: number | null;
  total?: number | null;
  createdAt: Date;
}

export interface GameWordEntity {
  id: string;
  word: string;
  active: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export type MiniGameType = 'memory_match' | 'love_order' | 'this_or_that';

export interface MiniGameConfigEntity {
  id: string;
  type: MiniGameType;
  title: string;
  instructions: string;
  items: string[];
  active: boolean;
  createdAt: Date;
  updatedAt: Date;
}
