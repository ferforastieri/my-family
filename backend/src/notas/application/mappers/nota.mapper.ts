import type { Mapper } from '@shared/application/mapper';
import type { NotaEntity } from '@notas/domain/entities/nota.entity';
import { NotaResponseDto } from '../../interfaces/dto/nota.dto';

export class NotaMapper implements Mapper<NotaEntity, NotaResponseDto> {
  toDto(source: NotaEntity): NotaResponseDto {
    return {
      id: source.id,
      titulo: source.titulo,
      conteudo: source.conteudo,
      data: source.data,
      createdAt: source.createdAt,
      updatedAt: source.updatedAt,
    };
  }
}

export const notaMapper = new NotaMapper();
