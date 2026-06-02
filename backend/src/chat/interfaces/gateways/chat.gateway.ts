import { ConnectedSocket, MessageBody, SubscribeMessage, WebSocketGateway, WebSocketServer } from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { WsSessionService } from '@auth/application/ws-session.service';
import { ChatService } from '../../application/chat.service';

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
    const user = await this.session.requireUser(client);
    return this.chat.usersForChat(user);
  }

  @SubscribeMessage('chat.conversations')
  async conversations(@ConnectedSocket() client: Socket) {
    const user = await this.session.getUser(client);
    return this.chat.listConversations(user);
  }

  @SubscribeMessage('chat.conversation.create')
  async createConversation(@ConnectedSocket() client: Socket, @MessageBody() body: { title?: string; participantIds: string[] }) {
    const user = await this.session.requireUser(client);
    const conversation = await this.chat.createDirectConversation(user, body);
    this.server?.emit('chat.conversation.created', conversation);
    return conversation;
  }

  @SubscribeMessage('chat.messages')
  async messages(@ConnectedSocket() client: Socket, @MessageBody() body: { conversationId: string }) {
    const user = await this.session.getUser(client);
    return this.chat.listMessages(body.conversationId, user);
  }

  @SubscribeMessage('chat.message.send')
  async send(@ConnectedSocket() client: Socket, @MessageBody() body: { conversationId: string; text?: string; mediaUrl?: string; mediaType?: 'image' | 'video'; senderName?: string }) {
    const user = await this.session.getUser(client);
    const message = await this.chat.sendMessage(body.conversationId, body, user);
    this.server?.emit('chat.message.created', message);
    return message;
  }
}
