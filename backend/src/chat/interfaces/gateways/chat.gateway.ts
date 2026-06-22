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
  ChatMessageActionDto,
  ChatMessageEditDto,
  ChatMessageSendDto,
  ChatMessagesReadDto,
  ChatTypingDto,
} from '../dto/chat.dto';
import { emitToTenant, tenantRoom } from '@tenancy/application/tenant-context';

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
    emitToTenant(this.server, 'chat.conversation.created', conversation);
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
    emitToTenant(this.server, 'chat.message.created', message);
    return { message: 'Mensagem enviada.', ...message };
  }

  @SubscribeMessage('chat.message.edit')
  async edit(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: ChatMessageEditDto,
  ) {
    const user = await this.session.requireAccess(client, 'chat');
    const message = await this.chat.editMessage(body, user);
    emitToTenant(this.server, 'chat.message.updated', message);
    return { message: 'Mensagem editada.', ...message };
  }

  @SubscribeMessage('chat.message.delete')
  async delete(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: ChatMessageActionDto,
  ) {
    const user = await this.session.requireAccess(client, 'chat');
    const message = await this.chat.deleteMessage(body.messageId, user);
    emitToTenant(this.server, 'chat.message.updated', message);
    return { message: 'Mensagem apagada.', ...message };
  }

  @SubscribeMessage('chat.messages.read')
  async read(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: ChatMessagesReadDto,
  ) {
    const user = await this.session.requireAccess(client, 'chat');
    const receipt = await this.chat.markMessagesRead(body.conversationId, user);
    emitToTenant(this.server, 'chat.messages.read', receipt);
    return receipt;
  }

  @SubscribeMessage('chat.typing')
  async typing(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: ChatTypingDto,
  ) {
    const user = await this.session.requireAccess(client, 'chat');
    const payload = {
      conversationId: body.conversationId,
      userId: user.id,
      senderName:
        user.name?.trim() || body.senderName?.trim() || user.email || 'Pessoa',
      isTyping: body.isTyping,
    };
    client.to(tenantRoom(user.tenantId)).emit('chat.typing', payload);
    return payload;
  }
}
