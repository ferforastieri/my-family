import { Injectable } from '@nestjs/common';
import { FotosRepository, FotoWrite } from '../infrastructure/repositories/fotos.repository';
import { UploadService } from '@shared/infrastructure/upload';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';

@Injectable()
export class FotosService {
  constructor(
    private fotos: FotosRepository,
    private upload: UploadService,
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
}
