import type { Mapper } from '@shared/application/mapper';
import type { CartaEntity } from '@shared/domain/entities';
import { CartaResponseDto } from '../interfaces/dto/carta.dto';

export class CartaMapper implements Mapper<CartaEntity, CartaResponseDto> {
  toDto(source: CartaEntity): CartaResponseDto {
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

export const cartaMapper = new CartaMapper();
