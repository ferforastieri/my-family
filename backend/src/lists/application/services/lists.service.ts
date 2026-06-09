import { BadRequestException, Injectable } from '@nestjs/common';
import type { UserEntity } from '@auth/domain/entities/user.entity';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import {
  FamilyListItemWrite,
  FamilyListWrite,
  ListsRepository,
} from '../../infrastructure/repositories/lists.repository';
import {
  familyListFactory,
  familyListItemFactory,
} from '../factories/list.factory';
import { familyListItemMapper, familyListMapper } from '../mappers/list.mapper';
import type {
  FamilyListItemWriteDto,
  FamilyListWriteDto,
} from '../../interfaces/dto/list.dto';
import { parseListMessage } from './list-message.parser';

@Injectable()
export class ListsService {
  constructor(private lists: ListsRepository) {}

  async listLists(query?: PaginationQuery) {
    const result = await this.lists.listLists(query);
    return {
      ...result,
      items: result.items.map((item) => familyListMapper.toDto(item)),
    };
  }

  async createList(data: FamilyListWriteDto, user?: UserEntity | null) {
    const normalized = familyListFactory.create(data);
    const title = normalized.title;
    if (!title) throw new BadRequestException('title é obrigatório');
    return familyListMapper.toDto(
      await this.lists.createList({
        title,
        description: normalized.description ?? null,
        createdBy: user?.id ?? null,
      }),
    );
  }

  async updateList(id: string, data: Partial<FamilyListWriteDto>) {
    const row = await this.lists.updateList(id, familyListFactory.create(data));
    return row ? familyListMapper.toDto(row) : null;
  }

  async deleteList(id: string) {
    return this.lists.deleteList(id);
  }

  async listItems(listId: string, query?: PaginationQuery) {
    const result = await this.lists.listItems(listId, query);
    return {
      ...result,
      items: result.items.map((item) => familyListItemMapper.toDto(item)),
    };
  }

  async createItem(data: FamilyListItemWriteDto, user?: UserEntity | null) {
    const normalized = familyListItemFactory.create(data);
    const text = normalized.text;
    if (!normalized.listId)
      throw new BadRequestException('listId é obrigatório');
    if (!text) throw new BadRequestException('text é obrigatório');
    return familyListItemMapper.toDto(
      await this.lists.createItem({
        listId: normalized.listId,
        text,
        checked: normalized.checked ?? false,
        createdBy: user?.id ?? null,
      }),
    );
  }

  async updateItem(id: string, data: Partial<FamilyListItemWriteDto>) {
    const row = await this.lists.updateItem(
      id,
      familyListItemFactory.create(data),
    );
    return row ? familyListItemMapper.toDto(row) : null;
  }

  async deleteItem(id: string) {
    return this.lists.deleteItem(id);
  }

  async addFromChat(text: string, user?: UserEntity | null) {
    const parsed = parseListMessage(text);
    if (!parsed) return null;
    let list = await this.lists.findListByTitle(parsed.title);
    list ??= await this.lists.createList({
      title: parsed.title,
      createdBy: user?.id ?? null,
    });
    const createdItems = [];
    for (const itemText of parsed.items) {
      createdItems.push(
        await this.createItem({ listId: list.id, text: itemText }, user),
      );
    }
    return { list: familyListMapper.toDto(list), items: createdItems };
  }
}
