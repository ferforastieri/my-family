import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  GameCompletionDocument,
  GameCompletionMongoDocument,
  GameWordDocument,
  GameWordMongoDocument,
  QuizQuestionDocument,
  QuizQuestionMongoDocument,
} from '@shared/infrastructure/database/schemas';
import { toId } from '@shared/infrastructure/database/mongo.utils';

export type QuizQuestionWrite = {
  question: string;
  options: string[];
  correctIndex: number;
  active?: boolean;
};

export type GameCompletionWrite = {
  game: 'quiz' | 'word_search';
  playerName: string;
  userId?: string | null;
  score?: number | null;
  total?: number | null;
};

export type GameWordWrite = {
  word: string;
  active?: boolean;
};

@Injectable()
export class GamesRepository {
  constructor(
    @InjectModel(QuizQuestionDocument.name)
    private questions: Model<QuizQuestionMongoDocument>,
    @InjectModel(GameCompletionDocument.name)
    private completions: Model<GameCompletionMongoDocument>,
    @InjectModel(GameWordDocument.name)
    private words: Model<GameWordMongoDocument>,
  ) {}

  private questionDto(doc: QuizQuestionMongoDocument) {
    return {
      id: toId(doc),
      question: doc.question,
      options: doc.options ?? [],
      correctIndex: doc.correctIndex,
      active: doc.active,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    };
  }

  private completionDto(doc: GameCompletionMongoDocument) {
    return {
      id: toId(doc),
      game: doc.game,
      playerName: doc.playerName,
      userId: doc.userId ?? null,
      score: doc.score ?? null,
      total: doc.total ?? null,
      createdAt: doc.createdAt,
    };
  }

  private wordDto(doc: GameWordMongoDocument) {
    return {
      id: toId(doc),
      word: doc.word,
      active: doc.active,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    };
  }

  async seedQuestions() {
    const count = await this.questions.countDocuments().exec();
    if (count > 0) return;
    await this.questions.insertMany([
      {
        question: 'Onde nosso amor mora primeiro?',
        options: ['No cuidado', 'Na pressa', 'No silêncio frio'],
        correctIndex: 0,
        active: true,
      },
      {
        question: 'Qual é o melhor plano para a família?',
        options: ['Crescer juntos', 'Competir sempre', 'Ficar distante'],
        correctIndex: 0,
        active: true,
      },
      {
        question: 'O que deixa uma casa mais parecida com lar?',
        options: ['Amor e fé', 'Só móveis novos', 'Barulho'],
        correctIndex: 0,
        active: true,
      },
    ]);
  }

  async seedWords() {
    const count = await this.words.countDocuments().exec();
    if (count > 0) return;
    await this.words.insertMany(
      [
        'FERNANDO',
        'MIRIAM',
        'FAMILIA',
        'AMOR',
        'TEMPLO',
        'FE',
        'LAR',
        'ETERNOS',
        'CARINHO',
        'FILHO',
        'JESUS',
        'ALIANCA',
      ].map((word) => ({ word, active: true })),
    );
  }

  async listQuestions(includeInactive = false) {
    await this.seedQuestions();
    const filter = includeInactive ? {} : { active: true };
    return (
      await this.questions.find(filter).sort({ createdAt: 1 }).exec()
    ).map((doc) => this.questionDto(doc));
  }

  async createQuestion(data: QuizQuestionWrite) {
    return this.questionDto(
      await this.questions.create({ ...data, active: data.active ?? true }),
    );
  }

  async updateQuestion(id: string, data: Partial<QuizQuestionWrite>) {
    const doc = await this.questions
      .findByIdAndUpdate(id, { $set: data }, { new: true })
      .exec();
    return doc ? this.questionDto(doc) : null;
  }

  async deleteQuestion(id: string) {
    const result = await this.questions.findByIdAndDelete(id).exec();
    return !!result;
  }

  async listWords(includeInactive = false) {
    await this.seedWords();
    const filter = includeInactive ? {} : { active: true };
    return (await this.words.find(filter).sort({ word: 1 }).exec()).map((doc) =>
      this.wordDto(doc),
    );
  }

  async createWord(data: GameWordWrite) {
    return this.wordDto(
      await this.words.create({ word: data.word, active: data.active ?? true }),
    );
  }

  async updateWord(id: string, data: Partial<GameWordWrite>) {
    const doc = await this.words
      .findByIdAndUpdate(id, { $set: data }, { new: true })
      .exec();
    return doc ? this.wordDto(doc) : null;
  }

  async deleteWord(id: string) {
    const result = await this.words.findByIdAndDelete(id).exec();
    return !!result;
  }

  async createCompletion(data: GameCompletionWrite) {
    return this.completionDto(await this.completions.create(data));
  }

  async stats() {
    const rows = await this.completions.aggregate([
      {
        $group: {
          _id: { game: '$game', playerName: '$playerName' },
          count: { $sum: 1 },
          bestScore: { $max: '$score' },
          lastAt: { $max: '$createdAt' },
        },
      },
      { $sort: { '_id.game': 1, count: -1, lastAt: -1 } },
    ]);
    return rows.map((row) => ({
      game: row._id.game,
      playerName: row._id.playerName,
      count: row.count,
      bestScore: row.bestScore ?? null,
      lastAt: new Date(row.lastAt).getTime(),
    }));
  }
}
