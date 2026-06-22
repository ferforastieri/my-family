import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { WsSessionService } from '@auth/application/services/ws-session.service';
import { GamesService } from '../../application/services/games.service';
import type {
  GameCompletionWriteDto,
  GameWordWriteDto,
  MiniGameConfigWriteDto,
  QuizQuestionWriteDto,
} from '../dto/game.dto';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import { emitToTenant } from '@tenancy/application/tenant-context';

@WebSocketGateway({ cors: { origin: '*' } })
export class GamesGateway {
  @WebSocketServer()
  server!: Server;

  constructor(
    private games: GamesService,
    private session: WsSessionService,
  ) {}

  @SubscribeMessage('games.quiz.list')
  async quizList(
    @ConnectedSocket() client: Socket,
    @MessageBody() query?: PaginationQuery,
  ) {
    await this.session.requireAccess(client, 'jogos');
    return this.games.quizPublic(query);
  }

  @SubscribeMessage('games.quiz.admin.list')
  async quizAdminList(
    @ConnectedSocket() client: Socket,
    @MessageBody() query?: PaginationQuery,
  ) {
    await this.session.requireAdmin(client);
    return this.games.quizAdmin(query);
  }

  @SubscribeMessage('games.quiz.create')
  async createQuestion(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: QuizQuestionWriteDto,
  ) {
    await this.session.requireAdmin(client);
    const row = await this.games.createQuestion(body);
    emitToTenant(this.server, 'games.quiz.created', row);
    return { message: 'Pergunta salva.', ...row };
  }

  @SubscribeMessage('games.quiz.update')
  async updateQuestion(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string; data: Partial<QuizQuestionWriteDto> },
  ) {
    await this.session.requireAdmin(client);
    const row = await this.games.updateQuestion(body.id, body.data);
    if (row) emitToTenant(this.server, 'games.quiz.updated', row);
    return row ? { message: 'Pergunta atualizada.', ...row } : row;
  }

  @SubscribeMessage('games.quiz.delete')
  async deleteQuestion(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string },
  ) {
    await this.session.requireAdmin(client);
    const ok = await this.games.deleteQuestion(body.id);
    if (ok) emitToTenant(this.server, 'games.quiz.deleted', { id: body.id });
    return { ok, message: 'Pergunta removida.' };
  }

  @SubscribeMessage('games.words.list')
  async wordsList(
    @ConnectedSocket() client: Socket,
    @MessageBody() query?: PaginationQuery,
  ) {
    await this.session.requireAccess(client, 'jogos');
    return this.games.wordsPublic(query);
  }

  @SubscribeMessage('games.words.admin.list')
  async wordsAdminList(
    @ConnectedSocket() client: Socket,
    @MessageBody() query?: PaginationQuery,
  ) {
    await this.session.requireAdmin(client);
    return this.games.wordsAdmin(query);
  }

  @SubscribeMessage('games.words.create')
  async createWord(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: GameWordWriteDto,
  ) {
    await this.session.requireAdmin(client);
    const row = await this.games.createWord(body);
    emitToTenant(this.server, 'games.words.created', row);
    return { message: 'Palavra salva.', ...row };
  }

  @SubscribeMessage('games.words.update')
  async updateWord(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string; data: Partial<GameWordWriteDto> },
  ) {
    await this.session.requireAdmin(client);
    const row = await this.games.updateWord(body.id, body.data);
    if (row) emitToTenant(this.server, 'games.words.updated', row);
    return row ? { message: 'Palavra atualizada.', ...row } : row;
  }

  @SubscribeMessage('games.words.delete')
  async deleteWord(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string },
  ) {
    await this.session.requireAdmin(client);
    const ok = await this.games.deleteWord(body.id);
    if (ok) emitToTenant(this.server, 'games.words.deleted', { id: body.id });
    return { ok, message: 'Palavra removida.' };
  }

  @SubscribeMessage('games.mini.list')
  async miniGamesList(
    @ConnectedSocket() client: Socket,
    @MessageBody() query?: PaginationQuery,
  ) {
    await this.session.requireAccess(client, 'jogos');
    return this.games.miniGamesPublic(query);
  }

  @SubscribeMessage('games.mini.admin.list')
  async miniGamesAdminList(
    @ConnectedSocket() client: Socket,
    @MessageBody() query?: PaginationQuery,
  ) {
    await this.session.requireAdmin(client);
    return this.games.miniGamesAdmin(query);
  }

  @SubscribeMessage('games.mini.create')
  async createMiniGame(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: MiniGameConfigWriteDto,
  ) {
    await this.session.requireAdmin(client);
    const row = await this.games.createMiniGame(body);
    emitToTenant(this.server, 'games.mini.created', row);
    return { message: 'Mini jogo salvo.', ...row };
  }

  @SubscribeMessage('games.mini.update')
  async updateMiniGame(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string; data: Partial<MiniGameConfigWriteDto> },
  ) {
    await this.session.requireAdmin(client);
    const row = await this.games.updateMiniGame(body.id, body.data);
    if (row) emitToTenant(this.server, 'games.mini.updated', row);
    return row ? { message: 'Mini jogo atualizado.', ...row } : row;
  }

  @SubscribeMessage('games.mini.delete')
  async deleteMiniGame(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string },
  ) {
    await this.session.requireAdmin(client);
    const ok = await this.games.deleteMiniGame(body.id);
    if (ok) emitToTenant(this.server, 'games.mini.deleted', { id: body.id });
    return { ok, message: 'Mini jogo removido.' };
  }

  @SubscribeMessage('games.complete')
  async complete(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: GameCompletionWriteDto,
  ) {
    const user = await this.session.requireAccess(client, 'jogos');
    const row = await this.games.complete(body, user);
    emitToTenant(this.server, 'games.stats.changed', row);
    return { message: 'Jogo concluído.', ...row };
  }

  @SubscribeMessage('games.stats')
  async stats(
    @ConnectedSocket() client: Socket,
    @MessageBody() query?: PaginationQuery,
  ) {
    await this.session.requireAdmin(client);
    return this.games.stats(query);
  }
}
