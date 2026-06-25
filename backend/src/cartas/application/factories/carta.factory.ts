import type { Factory } from '@shared/application/mapper';
import type { CartaWrite, CartaWriteInput } from '../models/carta.models';

export class CartaFactory implements Factory<
  Partial<CartaWriteInput>,
  Partial<CartaWrite>
> {
  create(input: CartaWriteInput): Omit<CartaWrite, 'tipo'>;
  create(input: Partial<CartaWriteInput>): Partial<CartaWrite>;
  create(input: Partial<CartaWriteInput>): Partial<CartaWrite> {
    return {
      titulo: input.titulo?.trim(),
      conteudo: input.conteudo?.trim(),
      data: input.data ? new Date(input.data) : undefined,
    };
  }
}

export const cartaFactory = new CartaFactory();
