import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  FotoDocument,
  FotoMongoDocument,
} from '@shared/infrastructure/database/schemas';
import {
  cleanUndefined,
  normalizePagination,
  paginated,
  PaginationQuery,
  toId,
} from '@shared/infrastructure/database/mongo.utils';
import type { FotoEntity } from '@fotos/domain/entities/foto.entity';

export type FotoWrite = Pick<FotoEntity, 'url' | 'tipo'> &
  Partial<Pick<FotoEntity, 'texto' | 'album' | 'data'>>;

@Injectable()
export class FotosRepository {
  constructor(
    @InjectModel(FotoDocument.name) private model: Model<FotoMongoDocument>,
  ) {}

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

  async list(query?: PaginationQuery) {
    const { page, limit, skip } = normalizePagination(query);
    const filter = this.albumFilter(query?.album);
    const [docs, total] = await Promise.all([
      this.model
        .find(filter)
        .sort({ data: -1, createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .exec(),
      this.model.countDocuments(filter).exec(),
    ]);
    return paginated(
      docs.map((doc) => this.toEntity(doc)!),
      total,
      page,
      limit,
    );
  }

  async listAlbums() {
    const rows = await this.model
      .aggregate<{ album?: string | null; count: number }>([
        {
          $group: {
            _id: '$album',
            count: { $sum: 1 },
          },
        },
        {
          $project: {
            _id: 0,
            album: '$_id',
            count: 1,
          },
        },
      ])
      .exec();

    const counts = new Map<string, number>();
    for (const row of rows) {
      const album = this.normalizeAlbum(row.album);
      counts.set(album, (counts.get(album) ?? 0) + row.count);
    }

    return [...counts.entries()]
      .map(([album, count]) => ({ album, count }))
      .sort((a, b) => a.album.localeCompare(b.album, 'pt-BR'));
  }

  async findById(id: string) {
    return this.toEntity(await this.model.findById(id).exec());
  }

  async findByUrl(url: string) {
    return this.toEntity(await this.model.findOne({ url }).exec());
  }

  async listUrls() {
    const rows = await this.model.find({}, { url: 1 }).exec();
    return rows.map((row) => row.url).filter(Boolean);
  }

  async create(data: FotoWrite) {
    return this.toEntity(
      await this.model.create({
        ...data,
        data: data.data ? new Date(data.data) : undefined,
      }),
    )!;
  }

  async update(id: string, data: Partial<FotoWrite>) {
    const normalized = {
      ...data,
      data: data.data ? new Date(data.data) : undefined,
    };
    return this.toEntity(
      await this.model
        .findByIdAndUpdate(
          id,
          { $set: cleanUndefined(normalized) },
          { new: true },
        )
        .exec(),
    );
  }

  async delete(id: string) {
    return !!(await this.model.findByIdAndDelete(id).exec());
  }

  private normalizeAlbum(album?: string | null) {
    const value = album?.trim();
    return value ? value : 'Geral';
  }

  private albumFilter(album?: string) {
    const value = album?.trim();
    if (!value) return {};
    if (value === 'Geral') {
      return {
        $or: [
          { album: 'Geral' },
          { album: null },
          { album: '' },
          { album: { $exists: false } },
        ],
      };
    }
    return { album: value };
  }
}
