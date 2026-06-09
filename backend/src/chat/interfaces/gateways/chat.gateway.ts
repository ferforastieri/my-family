import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { WsSessionService } from '@auth/application/services/ws-session.service';
import { ChatService } from '../../application/services/chat.service';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import type {
  ChatConversationCreateDto,
  ChatMessageSendDto,
} from '../dto/chat.dto';

@WebSocketGateway({ cors: { origin: '*' } })
export class ChatGateway {
  @WebSocketServer()
  private server?: Server;

  constructor(
    private chat: ChatService,
    private session: WsSessionService,
  ) {}

  @SubscribeMessage('chat.users')
  async users(@ConnectedSocket() client: Socket) {
    const user = await this.session.requireAccess(client, 'chat');
    return this.chat.usersForChat(user);
  }

  @SubscribeMessage('chat.conversations')
  async conversations(
    @ConnectedSocket() client: Socket,
    @MessageBody() query?: PaginationQuery,
  ) {
    const user = await this.session.requireAccess(client, 'chat');
    return this.chat.listConversations(user, query);
  }

  @SubscribeMessage('chat.conversation.create')
  async createConversation(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: ChatConversationCreateDto,
  ) {
    const user = await this.session.requireAccess(client, 'chat');
    const conversation = await this.chat.createDirectConversation(user, body);
    this.server?.emit('chat.conversation.created', conversation);
    return { message: 'Conversa criada.', ...conversation };
  }

  @SubscribeMessage('chat.messages')
  async messages(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { conversationId: string } & PaginationQuery,
  ) {
    const user = await this.session.requireAccess(client, 'chat');
    return this.chat.listMessages(body.conversationId, user, body);
  }

  @SubscribeMessage('chat.message.send')
  async send(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: ChatMessageSendDto,
  ) {
    const user = await this.session.requireAccess(client, 'chat');
    const message = await this.chat.sendMessage(
      body.conversationId,
      body,
      user,
    );
    this.server?.emit('chat.message.created', message);
    return { message: 'Mensagem enviada.', ...message };
  }
}
