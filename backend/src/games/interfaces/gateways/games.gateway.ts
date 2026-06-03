import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { WsSessionService } from '@auth/application/ws-session.service';
import { GamesService } from '../../application/games.service';
import type {
  GameWordWrite,
  QuizQuestionWrite,
} from '../../infrastructure/repositories/games.repository';

@WebSocketGateway({ cors: { origin: '*' } })
export class GamesGateway {
  @WebSocketServer()
  server!: Server;

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
    const row = await this.games.createQuestion(body);
    this.server.emit('games.quiz.created', row);
    return row;
  }

  @SubscribeMessage('games.quiz.update')
  async updateQuestion(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string; data: Partial<QuizQuestionWrite> },
  ) {
    await this.session.requireRole(client, ['admin']);
    const row = await this.games.updateQuestion(body.id, body.data);
    if (row) this.server.emit('games.quiz.updated', row);
    return row;
  }

  @SubscribeMessage('games.quiz.delete')
  async deleteQuestion(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string },
  ) {
    await this.session.requireRole(client, ['admin']);
    const ok = await this.games.deleteQuestion(body.id);
    if (ok) this.server.emit('games.quiz.deleted', { id: body.id });
    return { ok };
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
    const row = await this.games.createWord(body);
    this.server.emit('games.words.created', row);
    return row;
  }

  @SubscribeMessage('games.words.update')
  async updateWord(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string; data: Partial<GameWordWrite> },
  ) {
    await this.session.requireRole(client, ['admin']);
    const row = await this.games.updateWord(body.id, body.data);
    if (row) this.server.emit('games.words.updated', row);
    return row;
  }

  @SubscribeMessage('games.words.delete')
  async deleteWord(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string },
  ) {
    await this.session.requireRole(client, ['admin']);
    const ok = await this.games.deleteWord(body.id);
    if (ok) this.server.emit('games.words.deleted', { id: body.id });
    return { ok };
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
    const row = await this.games.complete(body, user);
    this.server.emit('games.stats.changed', row);
    return row;
  }

  @SubscribeMessage('games.stats')
  async stats(@ConnectedSocket() client: Socket) {
    await this.session.requireRole(client, ['admin']);
    return this.games.stats();
  }
}
