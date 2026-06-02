import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { Socket } from 'socket.io';
import { WsSessionService } from '@auth/application/ws-session.service';
import { GamesService } from '../../application/games.service';
import type {
  GameWordWrite,
  QuizQuestionWrite,
} from '../../infrastructure/repositories/games.repository';

@WebSocketGateway({ cors: { origin: '*' } })
export class GamesGateway {
  constructor(
    private games: GamesService,
    private session: WsSessionService,
  ) {}

  @SubscribeMessage('games.quiz.list')
  quizList() {
    return this.games.quizPublic();
  }

  @SubscribeMessage('games.quiz.admin.list')
  async quizAdminList(@ConnectedSocket() client: Socket) {
    await this.session.requireRole(client, ['admin']);
    return this.games.quizAdmin();
  }

  @SubscribeMessage('games.quiz.create')
  async createQuestion(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: QuizQuestionWrite,
  ) {
    await this.session.requireRole(client, ['admin']);
    return this.games.createQuestion(body);
  }

  @SubscribeMessage('games.quiz.update')
  async updateQuestion(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string; data: Partial<QuizQuestionWrite> },
  ) {
    await this.session.requireRole(client, ['admin']);
    return this.games.updateQuestion(body.id, body.data);
  }

  @SubscribeMessage('games.quiz.delete')
  async deleteQuestion(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string },
  ) {
    await this.session.requireRole(client, ['admin']);
    return { ok: await this.games.deleteQuestion(body.id) };
  }

  @SubscribeMessage('games.words.list')
  wordsList() {
    return this.games.wordsPublic();
  }

  @SubscribeMessage('games.words.admin.list')
  async wordsAdminList(@ConnectedSocket() client: Socket) {
    await this.session.requireRole(client, ['admin']);
    return this.games.wordsAdmin();
  }

  @SubscribeMessage('games.words.create')
  async createWord(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: GameWordWrite,
  ) {
    await this.session.requireRole(client, ['admin']);
    return this.games.createWord(body);
  }

  @SubscribeMessage('games.words.update')
  async updateWord(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string; data: Partial<GameWordWrite> },
  ) {
    await this.session.requireRole(client, ['admin']);
    return this.games.updateWord(body.id, body.data);
  }

  @SubscribeMessage('games.words.delete')
  async deleteWord(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string },
  ) {
    await this.session.requireRole(client, ['admin']);
    return { ok: await this.games.deleteWord(body.id) };
  }

  @SubscribeMessage('games.complete')
  async complete(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    body: {
      game: 'quiz' | 'word_search';
      playerName?: string;
      score?: number;
      total?: number;
    },
  ) {
    const user = await this.session.getUser(client);
    return this.games.complete(body, user);
  }

  @SubscribeMessage('games.stats')
  async stats(@ConnectedSocket() client: Socket) {
    await this.session.requireRole(client, ['admin']);
    return this.games.stats();
  }
}
