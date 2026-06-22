import { Injectable } from '@nestjs/common';
import {
  FotosRepository,
  FotoWrite,
} from '../../infrastructure/repositories/fotos.repository';
import { UploadContext, UploadService } from '@shared/infrastructure/upload';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import { JobsService } from '@shared/infrastructure/queue';
import { fotoFactory } from '../factories/foto.factory';
import { fotoMapper } from '../mappers/foto.mapper';
import type { FotoWriteDto } from '../../interfaces/dto/foto.dto';

@Injectable()
export class FotosService {
  constructor(
    private fotos: FotosRepository,
    private upload: UploadService,
    private jobs: JobsService,
  ) {}

  async findAll(query?: PaginationQuery) {
    const result = await this.fotos.list(query);
    return {
      ...result,
      items: result.items.map((item) => fotoMapper.toDto(item)),
    };
  }

  async findAlbums() {
    return this.fotos.listAlbums();
  }

  async findOne(id: string) {
    const item = await this.fotos.findById(id);
    return item ? fotoMapper.toDto(item) : null;
  }

  async create(data: FotoWriteDto) {
    return fotoMapper.toDto(
      await this.fotos.create(fotoFactory.create(data) as FotoWrite),
    );
  }

  async ensureFromChat(data: FotoWrite) {
    const existing = await this.fotos.findByUrl(data.url);
    const row = existing ?? (await this.fotos.create(data));
    return fotoMapper.toDto(row);
  }

  async update(id: string, data: Partial<FotoWriteDto>) {
    const row = await this.fotos.update(id, fotoFactory.create(data));
    return row ? fotoMapper.toDto(row) : null;
  }

  async delete(id: string) {
    const foto = await this.fotos.findById(id);
    const deleted = await this.fotos.delete(id);
    if (deleted && foto?.url?.includes('/fotos/')) {
      await this.upload.removeFile(foto.url);
    }
    return deleted;
  }

  async processUpload(relativePath: string) {
    await this.jobs.enqueueMediaProcessing({
      relativePath,
      context: 'fotos',
      mediaType: /\.(mp4|webm)$/i.test(relativePath) ? 'video' : 'image',
    });
  }

  async cleanupOrphanUploads() {
    const urls = new Set(await this.fotos.listUrls());
    return this.upload.removeOrphanFiles(
      UploadContext.Fotos,
      urls,
      24 * 60 * 60 * 1000,
    );
  }
}
