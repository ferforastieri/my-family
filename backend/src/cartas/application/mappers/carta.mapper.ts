import type { Mapper } from '@shared/application/mapper';
import type { CartaEntity } from '@cartas/domain/entities/carta.entity';
import { CartaResponseDto } from '../../interfaces/dto/carta.dto';

export class CartaMapper implements Mapper<CartaEntity, CartaResponseDto> {
  toDto(source: CartaEntity): CartaResponseDto {
    return {
      id: source.id,
      tipo: source.tipo,
      titulo: source.titulo,
      conteudo: source.conteudo,
      data: source.data,
      createdAt: source.createdAt,
      updatedAt: source.updatedAt,
    };
  }
}

export const cartaMapper = new CartaMapper();
