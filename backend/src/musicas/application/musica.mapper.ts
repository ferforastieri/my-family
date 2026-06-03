import type { Mapper } from '@shared/application/mapper';
import type { MusicaEntity } from '@shared/domain/entities';
import { MusicaResponseDto } from '../interfaces/dto/musica.dto';

export class MusicaMapper implements Mapper<MusicaEntity, MusicaResponseDto> {
  toDto(source: MusicaEntity): MusicaResponseDto {
    return {
      id: source.id,
      titulo: source.titulo,
      artista: source.artista,
      linkSpotify: source.linkSpotify,
      descricao: source.descricao ?? null,
      momento: source.momento,
      data: source.data,
      createdAt: source.createdAt,
      updatedAt: source.updatedAt,
    };
  }
}

export const musicaMapper = new MusicaMapper();
