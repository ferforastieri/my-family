import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  MusicaDocument,
  MusicaMongoDocument,
} from '../persistence/musica.schema';
import {
  cleanUndefined,
  normalizePagination,
  paginated,
  PaginationQuery,
  toId,
} from '@shared/infrastructure/database/mongo.utils';
import type { MusicaEntity } from '@musicas/domain/entities/musica.entity';

export type MusicaWrite = Pick<
  MusicaEntity,
  'titulo' | 'artista' | 'linkSpotify' | 'momento'
> &
  Partial<Pick<MusicaEntity, 'descricao' | 'data'>>;

@Injectable()
export class MusicasRepository {
  constructor(
    @InjectModel(MusicaDocument.name) private model: Model<MusicaMongoDocument>,
  ) {}

  private toEntity(doc: MusicaMongoDocument | null): MusicaEntity | null {
    if (!doc) return null;
    return {
      id: toId(doc),
      titulo: doc.titulo,
      artista: doc.artista,
      linkSpotify: doc.linkSpotify,
      descricao: doc.descricao ?? null,
      momento: doc.momento,
      data: doc.data,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    };
  }

  async list(query?: PaginationQuery) {
    const { page, limit, skip } = normalizePagination(query);
    const [docs, total] = await Promise.all([
      this.model.find().sort({ data: -1 }).skip(skip).limit(limit).exec(),
      this.model.countDocuments().exec(),
    ]);
    return paginated(
      docs.map((doc) => this.toEntity(doc)!),
      total,
      page,
      limit,
    );
  }

  async findById(id: string) {
    return this.toEntity(await this.model.findById(id).exec());
  }

  async create(data: MusicaWrite) {
    return this.toEntity(await this.model.create(data))!;
  }

  async update(id: string, data: Partial<MusicaWrite>) {
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
