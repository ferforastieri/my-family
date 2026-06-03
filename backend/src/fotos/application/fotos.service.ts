import { Injectable } from '@nestjs/common';
import {
  FotosRepository,
  FotoWrite,
} from '../infrastructure/repositories/fotos.repository';
import { UploadContext, UploadService } from '@shared/infrastructure/upload';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import { JobsService } from '@shared/infrastructure/queue';

@Injectable()
export class FotosService {
  constructor(
    private fotos: FotosRepository,
    private upload: UploadService,
    private jobs: JobsService,
  ) {}

  async findAll(query?: PaginationQuery) {
    return this.fotos.list(query);
  }

  async findOne(id: string) {
    return this.fotos.findById(id);
  }

  async create(data: FotoWrite) {
    return this.fotos.create(data);
  }

  async ensureFromChat(data: FotoWrite) {
    const existing = await this.fotos.findByUrl(data.url);
    if (existing) return existing;
    return this.fotos.create(data);
  }

  async update(id: string, data: Partial<FotoWrite>) {
    return this.fotos.update(id, data);
  }

  async delete(id: string) {
    const foto = await this.fotos.findById(id);
    const deleted = await this.fotos.delete(id);
    if (deleted && foto?.url?.startsWith('fotos/')) {
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
