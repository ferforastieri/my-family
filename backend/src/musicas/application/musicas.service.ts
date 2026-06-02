import { Injectable } from '@nestjs/common';
import { MusicasRepository, MusicaWrite } from '../infrastructure/repositories/musicas.repository';

@Injectable()
export class MusicasService {
  constructor(private musicas: MusicasRepository) {}

  async findAll() {
    return this.musicas.list();
  }

  async findOne(id: string) {
    return this.musicas.findById(id);
  }

  async create(data: MusicaWrite) {
    return this.musicas.create(data);
  }

  async update(id: string, data: Partial<MusicaWrite>) {
    return this.musicas.update(id, data);
  }

  async delete(id: string) {
    return this.musicas.delete(id);
  }
}

