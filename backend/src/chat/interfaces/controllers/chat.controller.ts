import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Access } from '@auth/decorators/access.decorator';
import { AccessGuard } from '@auth/guards/access.guard';
import type { UserEntity } from '@auth/domain/entities/user.entity';
import { PaginationMessageDto } from '@shared/interfaces/websocket/websocket.dto';
import { tenantRoom } from '@tenancy/application/tenant-context';
import { ChatService } from '../../application/services/chat.service';
import { ChatRealtimeGateway } from '../gateways/chat-realtime.gateway';
import {
  ChatConversationCreateDto,
  ChatMessageEditDto,
  ChatMessageSendDto,
  ChatTypingDto,
} from '../dto/chat.dto';

@Controller('chat')
@UseGuards(AccessGuard)
@Access('chat')
export class ChatController {
  constructor(
    private readonly chat: ChatService,
    private readonly realtime: ChatRealtimeGateway,
  ) {}

  @Get('users')
  users(@Req() request: { user: UserEntity }) {
    return this.chat.usersForChat(request.user);
  }

  @Get('conversations')
  conversations(
    @Req() request: { user: UserEntity },
    @Query() query: PaginationMessageDto,
  ) {
    return this.chat.listConversations(request.user, query);
  }

  @Post('conversations')
  async createConversation(
    @Req() request: { user: UserEntity },
    @Body() body: ChatConversationCreateDto,
  ) {
    const conversation = await this.chat.createDirectConversation(
      request.user,
      body,
    );
    this.realtime.emitToTenant('chat.conversation.created', conversation);
    return { message: 'Conversa criada.', ...conversation };
  }

  @Get('conversations/:id/messages')
  messages(
    @Req() request: { user: UserEntity },
    @Param('id') conversationId: string,
    @Query() query: PaginationMessageDto,
  ) {
    return this.chat.listMessages(conversationId, request.user, query);
  }

  @Post('conversations/:id/messages')
  async send(
    @Req() request: { user: UserEntity },
    @Param('id') conversationId: string,
    @Body() body: Omit<ChatMessageSendDto, 'conversationId'>,
  ) {
    const message = await this.chat.sendMessage(
      conversationId,
      body,
      request.user,
    );
    this.realtime.emitToTenant('chat.message.created', message);
    return { message: 'Mensagem enviada.', ...message };
  }

  @Patch('conversations/:id/read')
  async read(
    @Req() request: { user: UserEntity },
    @Param('id') conversationId: string,
  ) {
    const receipt = await this.chat.markMessagesRead(
      conversationId,
      request.user,
    );
    this.realtime.emitToTenant('chat.messages.read', receipt);
    return receipt;
  }

  @Patch('messages/:id')
  async edit(
    @Req() request: { user: UserEntity },
    @Param('id') messageId: string,
    @Body() body: Pick<ChatMessageEditDto, 'text'>,
  ) {
    const message = await this.chat.editMessage(
      { messageId, text: body.text },
      request.user,
    );
    this.realtime.emitToTenant('chat.message.updated', message);
    return { message: 'Mensagem editada.', ...message };
  }

  @Delete('messages/:id')
  async delete(@Req() request: { user: UserEntity }, @Param('id') id: string) {
    const message = await this.chat.deleteMessage(id, request.user);
    this.realtime.emitToTenant('chat.message.updated', message);
    return { message: 'Mensagem apagada.', ...message };
  }

  @Post('typing')
  typing(@Req() request: { user: UserEntity }, @Body() body: ChatTypingDto) {
    const payload = {
      conversationId: body.conversationId,
      userId: request.user.id,
      senderName:
        request.user.name?.trim() ||
        body.senderName?.trim() ||
        request.user.email ||
        'Pessoa',
      isTyping: body.isTyping,
    };
    this.realtime.to(tenantRoom(request.user.tenantId!), 'chat.typing', payload);
    return payload;
  }
}
