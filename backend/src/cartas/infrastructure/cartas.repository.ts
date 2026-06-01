import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { CartaDocument, CartaMongoDocument } from '@shared/infrastructure/database/mongo-schemas';
import { cleanUndefined, toId } from '@shared/infrastructure/database/mongo.utils';
import type { CartaEntity } from '@shared/domain/entities';

export type CartaWrite = Pick<CartaEntity, 'titulo' | 'conteudo'> & Partial<Pick<CartaEntity, 'data'>>;

@Injectable()
export class CartasRepository {
  constructor(@InjectModel(CartaDocument.name) private model: Model<CartaMongoDocument>) {}

  private toEntity(doc: CartaMongoDocument | null): CartaEntity | null {
    if (!doc) return null;
    return {
      id: toId(doc),
      titulo: doc.titulo,
      conteudo: doc.conteudo,
      data: doc.data,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    };
  }

  async list() {
    return (await this.model.find().sort({ data: -1 }).exec()).map((doc) => this.toEntity(doc)!);
  }

  async findById(id: string) {
    return this.toEntity(await this.model.findById(id).exec());
  }

  async create(data: CartaWrite) {
    return this.toEntity(await this.model.create(data))!;
  }

  async update(id: string, data: Partial<CartaWrite>) {
    return this.toEntity(await this.model.findByIdAndUpdate(id, { $set: cleanUndefined(data) }, { new: true }).exec());
  }

  async delete(id: string) {
    return !!(await this.model.findByIdAndDelete(id).exec());
  }
}
