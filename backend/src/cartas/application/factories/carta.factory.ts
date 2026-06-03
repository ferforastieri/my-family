import type { Factory } from '@shared/application/mapper';
import type { CartaWrite } from '../../infrastructure/repositories/cartas.repository';
import { CartaWriteDto } from '../../interfaces/dto/carta.dto';

export class CartaFactory implements Factory<
  Partial<CartaWriteDto>,
  Partial<CartaWrite>
> {
  create(input: Partial<CartaWriteDto>): Partial<CartaWrite> {
    return {
      titulo: input.titulo?.trim(),
      conteudo: input.conteudo?.trim(),
      data: input.data ? new Date(input.data) : undefined,
    };
  }
}

export const cartaFactory = new CartaFactory();
