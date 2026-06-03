import { BadRequestException, Injectable } from '@nestjs/common';
import {
  MusicasRepository,
  MusicaWrite,
} from '../infrastructure/repositories/musicas.repository';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import { musicaFactory } from './musica.factory';
import { musicaMapper } from './musica.mapper';
import type { MusicaWriteDto } from '../interfaces/dto/musica.dto';

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

  async findAll(query?: PaginationQuery) {
    const result = await this.musicas.list(query);
    return {
      ...result,
      items: result.items.map((item) => musicaMapper.toDto(item)),
    };
  }

  async findOne(id: string) {
    const item = await this.musicas.findById(id);
    return item ? musicaMapper.toDto(item) : null;
  }

  async create(data: MusicaWriteDto) {
    return musicaMapper.toDto(
      await this.musicas.create(this.validateCreate(data)),
    );
  }

  async update(id: string, data: Partial<MusicaWriteDto>) {
    const row = await this.musicas.update(id, this.validateUpdate(data));
    return row ? musicaMapper.toDto(row) : null;
  }

  async delete(id: string) {
    return this.musicas.delete(id);
  }

  private validateCreate(data: Partial<MusicaWriteDto>): MusicaWrite {
    const normalized = musicaFactory.create(data);
    const missing = requiredMusicFields.filter((field) => !normalized[field]);
    if (missing.length > 0) {
      throw new BadRequestException(
        `Informe ${missing.map((field) => this.fieldLabels[field]).join(', ')}.`,
      );
    }
    return normalized as MusicaWrite;
  }

  private validateUpdate(data: Partial<MusicaWriteDto>): Partial<MusicaWrite> {
    const normalized = musicaFactory.create(data);
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

  private readonly fieldLabels: Record<RequiredMusicField, string> = {
    titulo: 'título',
    artista: 'artista',
    linkSpotify: 'link do Spotify',
    momento: 'momento',
  };
}
