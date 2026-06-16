import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  NotaDocument,
  NotaMongoDocument,
} from '@shared/infrastructure/database/schemas';
import {
  cleanUndefined,
  normalizePagination,
  paginated,
  PaginationQuery,
  toId,
} from '@shared/infrastructure/database/mongo.utils';
import type { NotaEntity } from '@notas/domain/entities/nota.entity';

export type NotaWrite = Pick<NotaEntity, 'titulo' | 'conteudo'> &
  Partial<Pick<NotaEntity, 'data'>>;

@Injectable()
export class NotasRepository {
  constructor(
    @InjectModel(NotaDocument.name) private model: Model<NotaMongoDocument>,
  ) {}

  private toEntity(doc: NotaMongoDocument | null): NotaEntity | null {
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

  async list(query?: PaginationQuery) {
    const { page, limit, skip } = normalizePagination(query);
    const [docs, total] = await Promise.all([
      this.model.find().sort({ updatedAt: -1 }).skip(skip).limit(limit).exec(),
      this.model.countDocuments().exec(),
    ]);
    return paginated(
      docs.map((doc) => this.toEntity(doc)!),
      total,
      page,
      limit,
    );
  }

  async create(data: NotaWrite) {
    return this.toEntity(await this.model.create(data))!;
  }

  async update(id: string, data: Partial<NotaWrite>) {
    return this.toEntity(
      await this.model
        .findByIdAndUpdate(id, { $set: cleanUndefined(data) }, { new: true })
        .exec(),
    );
  }

  async delete(id: string) {
    return !!(await this.model.findByIdAndDelete(id).exec());
  }
}
