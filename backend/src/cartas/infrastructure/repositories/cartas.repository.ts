import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  CartaDocument,
  CartaMongoDocument,
} from '@shared/infrastructure/database/schemas';
import {
  cleanUndefined,
  normalizePagination,
  paginated,
  PaginationQuery,
  toId,
} from '@shared/infrastructure/database/mongo.utils';
import type { CartaEntity } from '@cartas/domain/entities/carta.entity';

export type CartaWrite = Pick<CartaEntity, 'tipo' | 'titulo' | 'conteudo'> &
  Partial<Pick<CartaEntity, 'data'>>;

@Injectable()
export class CartasRepository {
  constructor(
    @InjectModel(CartaDocument.name) private model: Model<CartaMongoDocument>,
  ) {}

  private toEntity(doc: CartaMongoDocument | null): CartaEntity | null {
    if (!doc) return null;
    return {
      id: toId(doc),
      tipo: doc.tipo,
      titulo: doc.titulo,
      conteudo: doc.conteudo,
      data: doc.data,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    };
  }

  async list(tipo: CartaEntity['tipo'], query?: PaginationQuery) {
    const filter = { tipo };
    const { page, limit, skip } = normalizePagination(query);
    const [docs, total] = await Promise.all([
      this.model.find(filter).sort({ data: -1 }).skip(skip).limit(limit).exec(),
      this.model.countDocuments(filter).exec(),
    ]);
    return paginated(
      docs.map((doc) => this.toEntity(doc)!),
      total,
      page,
      limit,
    );
  }

  async findById(id: string, tipo?: CartaEntity['tipo']) {
    return this.toEntity(
      await this.model.findOne({ _id: id, ...(tipo ? { tipo } : {}) }).exec(),
    );
  }

  async create(data: CartaWrite) {
    return this.toEntity(await this.model.create(data))!;
  }

  async update(
    id: string,
    tipo: CartaEntity['tipo'],
    data: Partial<CartaWrite>,
  ) {
    return this.toEntity(
      await this.model
        .findOneAndUpdate(
          { _id: id, tipo },
          { $set: cleanUndefined(data) },
          { new: true },
        )
        .exec(),
    );
  }

  async delete(id: string, tipo: CartaEntity['tipo']) {
    return !!(await this.model.findOneAndDelete({ _id: id, tipo }).exec());
  }
}
