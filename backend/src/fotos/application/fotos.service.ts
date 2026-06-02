import { Injectable } from '@nestjs/common';
import { FotosRepository, FotoWrite } from '../infrastructure/repositories/fotos.repository';
import { UploadService } from '@shared/infrastructure/upload';

@Injectable()
export class FotosService {
  constructor(
    private fotos: FotosRepository,
    private upload: UploadService,
  ) {}

  async findAll() {
    return this.fotos.list();
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
