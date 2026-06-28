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
import { ListsService } from '../../application/services/lists.service';
import {
  FamilyListItemUpdateDto,
  FamilyListItemWriteDto,
  FamilyListUpdateDto,
  FamilyListWriteDto,
} from '../dto/list.dto';
import { ListsRealtimeGateway } from '../gateways/lists-realtime.gateway';

@Controller('lists')
@UseGuards(AccessGuard)
@Access('listas')
export class ListsController {
  constructor(
    private readonly lists: ListsService,
    private readonly realtime: ListsRealtimeGateway,
  ) {}

  @Get()
  list(@Query() query: PaginationMessageDto) {
    return this.lists.listLists(query);
  }

  @Post()
  async create(
    @Req() request: { user: UserEntity },
    @Body() body: FamilyListWriteDto,
  ) {
    const row = await this.lists.createList(body, request.user);
    this.realtime.emitListCreated(row);
    return { message: 'Lista criada.', ...row };
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() body: FamilyListUpdateDto) {
    const row = await this.lists.updateList(id, body);
    if (row) this.realtime.emitListUpdated(row);
    return row ? { message: 'Lista atualizada.', ...row } : row;
  }

  @Delete(':id')
  async delete(@Param('id') id: string) {
    const ok = await this.lists.deleteList(id);
    if (ok) this.realtime.emitListDeleted(id);
    return { ok, message: 'Lista removida.' };
  }

  @Get(':id/items')
  items(@Param('id') id: string, @Query() query: PaginationMessageDto) {
    return this.lists.listItems(id, query);
  }

  @Post(':id/items')
  async createItem(
    @Param('id') id: string,
    @Req() request: { user: UserEntity },
    @Body() body: Omit<FamilyListItemWriteDto, 'listId'>,
  ) {
    const row = await this.lists.createItem(
      { ...body, listId: id },
      request.user,
    );
    this.realtime.emitItemCreated(row);
    return { message: 'Item adicionado.', ...row };
  }

  @Patch('items/:id')
  async updateItem(
    @Param('id') id: string,
    @Body() body: FamilyListItemUpdateDto,
  ) {
    const row = await this.lists.updateItem(id, body);
    if (row) this.realtime.emitItemUpdated(row);
    return row ? { message: 'Item atualizado.', ...row } : row;
  }

  @Delete('items/:id')
  async deleteItem(@Param('id') id: string) {
    const result = await this.lists.deleteItem(id);
    if (result.ok) this.realtime.emitItemDeleted(id, result.listId);
    return { ok: result.ok, message: 'Item removido.' };
  }
}
