import type { CartaEntity } from '../../domain/entities/carta.entity';

export type CartaWriteInput = Pick<CartaEntity, 'titulo' | 'conteudo'> & {
  data?: string | Date;
};

export type CartaWrite = Pick<CartaEntity, 'tipo' | 'titulo' | 'conteudo'> &
  Partial<Pick<CartaEntity, 'data'>>;
