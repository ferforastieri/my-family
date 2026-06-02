import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { FotoDocument, FotoMongoDocument } from '@shared/infrastructure/database/schemas';
import { cleanUndefined, toId } from '@shared/infrastructure/database/mongo.utils';
import type { FotoEntity } from '@shared/domain/entities';

export type FotoWrite = Pick<FotoEntity, 'url' | 'tipo'> & Partial<Pick<FotoEntity, 'texto' | 'album' | 'data'>>;

@Injectable()
export class FotosRepository {
  constructor(@InjectModel(FotoDocument.name) private model: Model<FotoMongoDocument>) {}

  private toEntity(doc: FotoMongoDocument | null): FotoEntity | null {
    if (!doc) return null;
    return {
      id: toId(doc),
      url: doc.url,
      texto: doc.texto ?? null,
      album: doc.album ?? null,
      tipo: doc.tipo,
      data: doc.data ?? null,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    };
  }

  async list() {
    return (await this.model.find().sort({ data: -1, createdAt: -1 }).exec()).map((doc) => this.toEntity(doc)!);
  }

  async findById(id: string) {
    return this.toEntity(await this.model.findById(id).exec());
  }

  async create(data: FotoWrite) {
    return this.toEntity(await this.model.create({ ...data, data: data.data ? new Date(data.data) : undefined }))!;
  }

  async update(id: string, data: Partial<FotoWrite>) {
    const normalized = { ...data, data: data.data ? new Date(data.data) : undefined };
    return this.toEntity(await this.model.findByIdAndUpdate(id, { $set: cleanUndefined(normalized) }, { new: true }).exec());
  }

  async delete(id: string) {
    return !!(await this.model.findByIdAndDelete(id).exec());
  }
}
