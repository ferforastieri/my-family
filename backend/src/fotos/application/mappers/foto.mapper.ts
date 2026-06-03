import type { Mapper } from '@shared/application/mapper';
import type { FotoEntity } from '@fotos/domain/entities/foto.entity';
import { FotoResponseDto } from '../../interfaces/dto/foto.dto';

export class FotoMapper implements Mapper<FotoEntity, FotoResponseDto> {
  toDto(source: FotoEntity): FotoResponseDto {
    return {
      id: source.id,
      url: source.url,
      texto: source.texto ?? null,
      album: source.album ?? null,
      tipo: source.tipo,
      data: source.data ?? null,
      createdAt: source.createdAt,
      updatedAt: source.updatedAt,
    };
  }
}

export const fotoMapper = new FotoMapper();
