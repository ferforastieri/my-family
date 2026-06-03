import { BadRequestException, Injectable } from '@nestjs/common';
import {
  MusicasRepository,
  MusicaWrite,
} from '../infrastructure/repositories/musicas.repository';

const requiredMusicFields = [
  'titulo',
  'artista',
  'linkSpotify',
  'momento',
] as const;
type RequiredMusicField = (typeof requiredMusicFields)[number];

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
    return this.musicas.create(this.validateCreate(data));
  }

  async update(id: string, data: Partial<MusicaWrite>) {
    return this.musicas.update(id, this.validateUpdate(data));
  }

  async delete(id: string) {
    return this.musicas.delete(id);
  }

  private validateCreate(data: Partial<MusicaWrite>): MusicaWrite {
    const normalized = this.normalize(data);
    const missing = requiredMusicFields.filter((field) => !normalized[field]);
    if (missing.length > 0) {
      throw new BadRequestException(
        `Informe ${missing.map((field) => this.fieldLabels[field]).join(', ')}.`,
      );
    }
    return normalized as MusicaWrite;
  }

  private validateUpdate(data: Partial<MusicaWrite>): Partial<MusicaWrite> {
    const normalized = this.normalize(data);
    const empty = requiredMusicFields.filter(
      (field) =>
        Object.prototype.hasOwnProperty.call(data, field) && !normalized[field],
    );
    if (empty.length > 0) {
      throw new BadRequestException(
        `${empty.map((field) => this.fieldLabels[field]).join(', ')} não pode ficar vazio.`,
      );
    }
    return normalized;
  }

  private normalize(data: Partial<MusicaWrite>): Partial<MusicaWrite> {
    return {
      ...data,
      titulo: data.titulo?.trim(),
      artista: data.artista?.trim(),
      linkSpotify: data.linkSpotify?.trim(),
      momento: data.momento?.trim(),
      descricao: data.descricao?.trim(),
    };
  }

  private readonly fieldLabels: Record<RequiredMusicField, string> = {
    titulo: 'título',
    artista: 'artista',
    linkSpotify: 'link do Spotify',
    momento: 'momento',
  };
}
