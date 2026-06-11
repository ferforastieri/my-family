import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  GameCompletionDocument,
  GameCompletionMongoDocument,
  MiniGameConfigDocument,
  MiniGameConfigMongoDocument,
  GameWordDocument,
  GameWordMongoDocument,
  QuizQuestionDocument,
  QuizQuestionMongoDocument,
} from '@shared/infrastructure/database/schemas';
import {
  normalizePagination,
  paginated,
  PaginationQuery,
  toId,
} from '@shared/infrastructure/database/mongo.utils';

export type QuizQuestionWrite = {
  question: string;
  options: string[];
  correctIndex: number;
  active?: boolean;
};

export type GameCompletionWrite = {
  game: string;
  playerName: string;
  userId?: string | null;
  score?: number | null;
  total?: number | null;
};

export type MiniGameConfigWrite = {
  type: 'memory_match' | 'love_order' | 'this_or_that';
  title: string;
  instructions?: string;
  items: string[];
  active?: boolean;
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
    @InjectModel(MiniGameConfigDocument.name)
    private miniGames: Model<MiniGameConfigMongoDocument>,
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

  private miniGameDto(doc: MiniGameConfigMongoDocument) {
    return {
      id: toId(doc),
      type: doc.type,
      title: doc.title,
      instructions: doc.instructions ?? '',
      items: doc.items ?? [],
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

  async seedMiniGames() {
    const defaults: MiniGameConfigWrite[] = [
      {
        type: 'memory_match',
        title: 'Memória da Família',
        instructions: 'Encontre os pares de lembranças iguais.',
        items: ['Amor', 'Templo', 'Rudy', 'Shopping', 'Filme', 'Fernando'],
        active: true,
      },
      {
        type: 'love_order',
        title: 'Linha do Amor',
        instructions: 'Toque nos momentos na ordem certa da história.',
        items: [
          'Mutual',
          'Primeiro encontro',
          'Namoro',
          'Casamento',
          'Fernando',
        ],
        active: true,
      },
      {
        type: 'this_or_that',
        title: 'Quiz Isso ou Aquilo',
        instructions:
          'Escolha a resposta correta em cada rodada. Use Pergunta|Opção A|Opção B|Resposta correta.',
        items: [
          'Onde nos conhecemos?|Mutual|Shopping|Mutual',
          'Quando começamos a namorar?|12 de outubro de 2024|15 de abril de 2025|12 de outubro de 2024',
          'Quando casamos?|15 de abril de 2025|12 de outubro de 2024|15 de abril de 2025',
          'Qual é o nome do nosso cachorro?|Rudy|Fernando|Rudy',
          'Qual será o nome do nosso filho?|Fernando|Rudy|Fernando',
        ],
        active: true,
      },
    ];
    await Promise.all(
      defaults.map((game) =>
        this.miniGames
          .updateOne(
            { type: game.type },
            { $setOnInsert: game },
            { upsert: true },
          )
          .exec(),
      ),
    );
  }

  async listQuestions(includeInactive = false, query?: PaginationQuery) {
    await this.seedQuestions();
    const filter = includeInactive ? {} : { active: true };
    const { page, limit, skip } = normalizePagination(query, {
      page: 1,
      limit: 20,
      maxLimit: 100,
    });
    const [docs, total] = await Promise.all([
      this.questions
        .find(filter)
        .sort({ createdAt: 1 })
        .skip(skip)
        .limit(limit)
        .exec(),
      this.questions.countDocuments(filter).exec(),
    ]);
    return paginated(
      docs.map((doc) => this.questionDto(doc)),
      total,
      page,
      limit,
    );
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

  async listWords(includeInactive = false, query?: PaginationQuery) {
    await this.seedWords();
    const filter = includeInactive ? {} : { active: true };
    const { page, limit, skip } = normalizePagination(query, {
      page: 1,
      limit: 30,
      maxLimit: 100,
    });
    const [docs, total] = await Promise.all([
      this.words.find(filter).sort({ word: 1 }).skip(skip).limit(limit).exec(),
      this.words.countDocuments(filter).exec(),
    ]);
    return paginated(
      docs.map((doc) => this.wordDto(doc)),
      total,
      page,
      limit,
    );
  }

  async listMiniGames(includeInactive = false, query?: PaginationQuery) {
    await this.seedMiniGames();
    const filter = includeInactive ? {} : { active: true };
    const { page, limit, skip } = normalizePagination(query, {
      page: 1,
      limit: 30,
      maxLimit: 100,
    });
    const [docs, total] = await Promise.all([
      this.miniGames
        .find(filter)
        .sort({ createdAt: 1 })
        .skip(skip)
        .limit(limit)
        .exec(),
      this.miniGames.countDocuments(filter).exec(),
    ]);
    return paginated(
      docs.map((doc) => this.miniGameDto(doc)),
      total,
      page,
      limit,
    );
  }

  async createMiniGame(data: MiniGameConfigWrite) {
    return this.miniGameDto(
      await this.miniGames.create({ ...data, active: data.active ?? true }),
    );
  }

  async updateMiniGame(id: string, data: Partial<MiniGameConfigWrite>) {
    const doc = await this.miniGames
      .findByIdAndUpdate(id, { $set: data }, { new: true })
      .exec();
    return doc ? this.miniGameDto(doc) : null;
  }

  async deleteMiniGame(id: string) {
    const result = await this.miniGames.findByIdAndDelete(id).exec();
    return !!result;
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

  async stats(query?: PaginationQuery) {
    const { page, limit, skip } = normalizePagination(query, {
      page: 1,
      limit: 20,
      maxLimit: 100,
    });
    const [result] = await this.completions.aggregate([
      {
        $group: {
          _id: { game: '$game', playerName: '$playerName' },
          count: { $sum: 1 },
          bestScore: { $max: '$score' },
          lastAt: { $max: '$createdAt' },
        },
      },
      { $sort: { '_id.game': 1, count: -1, lastAt: -1 } },
      {
        $facet: {
          items: [{ $skip: skip }, { $limit: limit }],
          total: [{ $count: 'count' }],
        },
      },
    ]);
    const rows = result?.items ?? [];
    const total = result?.total?.[0]?.count ?? 0;
    return paginated(
      rows.map((row) => ({
        game: row._id.game,
        playerName: row._id.playerName,
        count: row.count,
        bestScore: row.bestScore ?? null,
        lastAt: new Date(row.lastAt).getTime(),
      })),
      total,
      page,
      limit,
    );
  }
}
