import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Access } from '@auth/decorators/access.decorator';
import type { UserEntity } from '@auth/domain/entities/user.entity';
import { AccessGuard } from '@auth/guards/access.guard';
import { JwtAuthGuard } from '@auth/guards/jwt-auth.guard';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import { ListsService } from '../../application/services/lists.service';
import { FamilyListItemWriteDto, FamilyListWriteDto } from '../dto/list.dto';
import { ListsRealtimeGateway } from '../gateways/lists-realtime.gateway';

@Controller('lists')
@UseGuards(JwtAuthGuard, AccessGuard)
@Access('listas')
export class ListsController {
  constructor(
    private readonly lists: ListsService,
    private readonly realtime: ListsRealtimeGateway,
  ) {}

  @Get()
  list(@Query() query: PaginationQuery) {
    return this.lists.listLists(query);
  }

  @Post()
  async create(
    @Req() request: { user: UserEntity },
    @Body() data: FamilyListWriteDto,
  ) {
    const row = await this.lists.createList(data, request.user);
    this.realtime.emitListCreated(row);
    return { message: 'Lista criada.', ...row };
  }

  @Put(':id')
  async update(
    @Param('id') id: string,
    @Body() data: Partial<FamilyListWriteDto>,
  ) {
    const row = await this.lists.updateList(id, data);
    if (row) this.realtime.emitListUpdated(row);
    return row ? { message: 'Lista atualizada.', ...row } : row;
  }

  @Delete(':id')
  async delete(@Param('id') id: string) {
    const ok = await this.lists.deleteList(id);
    if (ok) this.realtime.emitListDeleted(id);
    return { ok, message: 'Lista removida.' };
  }

  @Get(':listId/items')
  items(@Param('listId') listId: string, @Query() query: PaginationQuery) {
    return this.lists.listItems(listId, query);
  }

  @Post(':listId/items')
  async createItem(
    @Req() request: { user: UserEntity },
    @Param('listId') listId: string,
    @Body() data: FamilyListItemWriteDto,
  ) {
    const row = await this.lists.createItem({ ...data, listId }, request.user);
    this.realtime.emitItemCreated(row);
    return { message: 'Item adicionado.', ...row };
  }

  @Put('items/:id')
  async updateItem(
    @Param('id') id: string,
    @Body() data: Partial<FamilyListItemWriteDto>,
  ) {
    const row = await this.lists.updateItem(id, data);
    if (row) this.realtime.emitItemUpdated(row);
    return row ? { message: 'Item atualizado.', ...row } : row;
  }

  @Delete('items/:id')
  async deleteItem(@Param('id') id: string) {
    const ok = await this.lists.deleteItem(id);
    if (ok) this.realtime.emitItemDeleted(id);
    return { ok, message: 'Item removido.' };
  }
}
