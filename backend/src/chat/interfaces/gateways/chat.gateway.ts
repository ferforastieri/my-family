import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { UseGuards } from '@nestjs/common';
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
import { WsRateLimitGuard } from '@shared/infrastructure/security/ws-rate-limit.guard';

@WebSocketGateway()
@UseGuards(WsRateLimitGuard)
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
    this.server
      ?.to(`tenant:${user.tenantId}`)
      .emit('chat.conversation.created', conversation);
    return { message: 'Conversa criada.', ...conversation };
  }

  @SubscribeMessage('chat.messages')
  async messages(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { conversationId: string } & PaginationQuery,
  ) {
    const user = await this.session.requireAccess(client, 'chat');
    const messages = await this.chat.listMessages(
      body.conversationId,
      user,
      body,
    );
    await client.join(`conversation:${body.conversationId}`);
    return messages;
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
    this.server
      ?.to(`conversation:${body.conversationId}`)
      .emit('chat.message.created', message);
    return { message: 'Mensagem enviada.', ...message };
  }

  @SubscribeMessage('chat.message.edit')
  async edit(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: ChatMessageEditDto,
  ) {
    const user = await this.session.requireAccess(client, 'chat');
    const message = await this.chat.editMessage(body, user);
    this.server
      ?.to(`tenant:${user.tenantId}`)
      .emit('chat.message.updated', message);
    return { message: 'Mensagem editada.', ...message };
  }

  @SubscribeMessage('chat.message.delete')
  async delete(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: ChatMessageActionDto,
  ) {
    const user = await this.session.requireAccess(client, 'chat');
    const message = await this.chat.deleteMessage(body.messageId, user);
    this.server
      ?.to(`tenant:${user.tenantId}`)
      .emit('chat.message.updated', message);
    return { message: 'Mensagem apagada.', ...message };
  }

  @SubscribeMessage('chat.messages.read')
  async read(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: ChatMessagesReadDto,
  ) {
    const user = await this.session.requireAccess(client, 'chat');
    const receipt = await this.chat.markMessagesRead(body.conversationId, user);
    this.server
      ?.to(`conversation:${body.conversationId}`)
      .emit('chat.messages.read', receipt);
    return receipt;
  }

  @SubscribeMessage('chat.typing')
  async typing(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: ChatTypingDto,
  ) {
    const user = await this.session.requireAccess(client, 'chat');
    await this.chat.assertConversationAccess(body.conversationId, user);
    const payload = {
      conversationId: body.conversationId,
      userId: user.id,
      senderName:
        user.name?.trim() ||
        body.senderName?.trim() ||
        user.phoneNumber ||
        'Pessoa',
      isTyping: body.isTyping,
    };
    client
      .to(`conversation:${body.conversationId}`)
      .emit('chat.typing', payload);
    return payload;
  }
}
