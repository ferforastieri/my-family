import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { CartaDocument, CartaMongoDocument } from '../persistence/carta.schema';
import {
  cleanUndefined,
  normalizePagination,
  paginated,
  PaginationQuery,
  toId,
} from '@shared/infrastructure/database/mongo.utils';
import type { CartaEntity } from '@cartas/domain/entities/carta.entity';
import type { CartaWrite } from '../../application/models/carta.models';
import type { CartasRepositoryPort } from '../../application/ports/cartas.repository.port';

@Injectable()
export class CartasRepository implements CartasRepositoryPort {
  constructor(
    @InjectModel(CartaDocument.name) private model: Model<CartaMongoDocument>,
  ) {}

  private toEntity(doc: CartaMongoDocument): CartaEntity;
  private toEntity(doc: null): null;
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
      docs.map((doc) => this.toEntity(doc)),
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
    return this.toEntity(await this.model.create(data));
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

  async listForPublic(
    tipo: CartaEntity['tipo'],
    limit: number,
    direction: 1 | -1,
  ) {
    const documents = await this.model
      .find({ tipo })
      .sort({ createdAt: direction })
      .limit(Math.min(Math.max(limit, 1), 100))
      .exec();
    return documents.map((document) => this.toEntity(document));
  }
}
