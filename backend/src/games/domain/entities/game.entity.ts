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
  game: 'quiz' | 'word_search';
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
