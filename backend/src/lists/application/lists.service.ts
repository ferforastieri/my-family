import { BadRequestException, Injectable } from '@nestjs/common';
import type { UserEntity } from '@shared/domain/entities';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import { FamilyListItemWrite, FamilyListWrite, ListsRepository } from '../infrastructure/repositories/lists.repository';

@Injectable()
export class ListsService {
  constructor(private lists: ListsRepository) {}

  async listLists(query?: PaginationQuery) {
    return this.lists.listLists(query);
  }

  async createList(data: FamilyListWrite, user?: UserEntity | null) {
    const title = data.title?.trim();
    if (!title) throw new BadRequestException('title é obrigatório');
    return this.lists.createList({
      title,
      description: data.description?.trim() || null,
      createdBy: user?.id ?? data.createdBy ?? null,
    });
  }

  async updateList(id: string, data: Partial<FamilyListWrite>) {
    return this.lists.updateList(id, {
      title: data.title?.trim(),
      description: data.description?.trim(),
    });
  }

  async deleteList(id: string) {
    return this.lists.deleteList(id);
  }

  async listItems(listId: string, query?: PaginationQuery) {
    return this.lists.listItems(listId, query);
  }

  async createItem(data: FamilyListItemWrite, user?: UserEntity | null) {
    const text = data.text?.trim();
    if (!data.listId) throw new BadRequestException('listId é obrigatório');
    if (!text) throw new BadRequestException('text é obrigatório');
    return this.lists.createItem({
      listId: data.listId,
      text,
      checked: data.checked ?? false,
      createdBy: user?.id ?? data.createdBy ?? null,
    });
  }

  async updateItem(id: string, data: Partial<FamilyListItemWrite>) {
    return this.lists.updateItem(id, {
      text: data.text?.trim(),
      checked: data.checked,
    });
  }

  async deleteItem(id: string) {
    return this.lists.deleteItem(id);
  }

  async addFromChat(text: string, user?: UserEntity | null) {
    const parsed = parseListMessage(text);
    if (!parsed) return null;
    let list = await this.lists.findListByTitle(parsed.title);
    list ??= await this.createList({ title: parsed.title }, user);
    const createdItems = [];
    for (const itemText of parsed.items) {
      createdItems.push(await this.createItem({ listId: list.id, text: itemText }, user));
    }
    return { list, items: createdItems };
  }
}

function parseListMessage(text: string) {
  const trimmed = text.trim();
  const match = /^lista\s*:\s*(.*)$/i.exec(trimmed);
  if (!match) return null;
  const rest = match[1].trim();
  const lines = rest.split(/\r?\n/).map((line) => line.trim()).filter(Boolean);
  const first = lines.shift() ?? '';
  const inline = first.includes(':') ? first.split(':') : null;
  const title = (inline ? inline.shift() : first)?.trim() || 'Lista';
  const firstItems = inline?.join(':') ?? '';
  const items = [firstItems, ...lines]
    .flatMap((line) => line.split(/[,;]/))
    .map((item) => item.replace(/^[-*•]\s*/, '').trim())
    .filter(Boolean);
  return { title, items: items.length ? items : ['Novo item'] };
}
