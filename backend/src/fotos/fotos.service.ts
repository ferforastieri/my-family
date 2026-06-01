import { Injectable } from '@nestjs/common';
import { FotosRepository, FotoWrite } from './infrastructure/fotos.repository';

@Injectable()
export class FotosService {
  constructor(private fotos: FotosRepository) {}

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
    return this.fotos.delete(id);
  }
}

