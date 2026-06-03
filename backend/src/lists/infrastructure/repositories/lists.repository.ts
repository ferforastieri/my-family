import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  FamilyListDocument,
  FamilyListItemDocument,
  FamilyListItemMongoDocument,
  FamilyListMongoDocument,
} from '@shared/infrastructure/database/schemas';
import { cleanUndefined, toId } from '@shared/infrastructure/database/mongo.utils';
import type { FamilyListEntity, FamilyListItemEntity } from '@shared/domain/entities';

export type FamilyListWrite = {
  title: string;
  description?: string | null;
  createdBy?: string | null;
};

export type FamilyListItemWrite = {
  listId: string;
  text: string;
  checked?: boolean;
  createdBy?: string | null;
};

@Injectable()
export class ListsRepository {
  constructor(
    @InjectModel(FamilyListDocument.name) private lists: Model<FamilyListMongoDocument>,
    @InjectModel(FamilyListItemDocument.name) private items: Model<FamilyListItemMongoDocument>,
  ) {}

  private toList(doc: FamilyListMongoDocument | null): FamilyListEntity | null {
    if (!doc) return null;
    return {
      id: toId(doc),
      title: doc.title,
      description: doc.description ?? null,
      createdBy: doc.createdBy ?? null,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    };
  }

  private toItem(doc: FamilyListItemMongoDocument | null): FamilyListItemEntity | null {
    if (!doc) return null;
    return {
      id: toId(doc),
      listId: doc.listId,
      text: doc.text,
      checked: doc.checked,
      createdBy: doc.createdBy ?? null,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    };
  }

  async listLists() {
    return (await this.lists.find().sort({ updatedAt: -1 }).exec()).map((doc) => this.toList(doc)!);
  }

  async findList(id: string) {
    return this.toList(await this.lists.findById(id).exec());
  }

  async findListByTitle(title: string) {
    return this.toList(await this.lists.findOne({ title: new RegExp(`^${escapeRegExp(title)}$`, 'i') }).exec());
  }

  async createList(data: FamilyListWrite) {
    return this.toList(await this.lists.create(cleanUndefined(data)))!;
  }

  async updateList(id: string, data: Partial<FamilyListWrite>) {
    return this.toList(await this.lists.findByIdAndUpdate(id, { $set: cleanUndefined(data) }, { new: true }).exec());
  }

  async deleteList(id: string) {
    await this.items.deleteMany({ listId: id }).exec();
    return !!(await this.lists.findByIdAndDelete(id).exec());
  }

  async listItems(listId: string) {
    return (await this.items.find({ listId }).sort({ checked: 1, createdAt: -1 }).exec()).map((doc) => this.toItem(doc)!);
  }

  async createItem(data: FamilyListItemWrite) {
    const item = this.toItem(await this.items.create(cleanUndefined(data)))!;
    await this.lists.findByIdAndUpdate(data.listId, { $set: { updatedAt: new Date() } }).exec();
    return item;
  }

  async updateItem(id: string, data: Partial<FamilyListItemWrite>) {
    const item = this.toItem(await this.items.findByIdAndUpdate(id, { $set: cleanUndefined(data) }, { new: true }).exec());
    if (item) await this.lists.findByIdAndUpdate(item.listId, { $set: { updatedAt: new Date() } }).exec();
    return item;
  }

  async deleteItem(id: string) {
    const item = await this.items.findById(id).exec();
    const ok = !!(await this.items.findByIdAndDelete(id).exec());
    if (ok && item) await this.lists.findByIdAndUpdate(item.listId, { $set: { updatedAt: new Date() } }).exec();
    return { ok, listId: item?.listId };
  }
}

function escapeRegExp(value: string) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

