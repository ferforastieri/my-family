import type {
  PaginatedResult,
  PaginationQuery,
} from '@shared/application/pagination';
import type { CartaEntity } from '../../domain/entities/carta.entity';
import type { CartaWrite } from '../models/carta.models';

export const CARTAS_REPOSITORY = Symbol('CARTAS_REPOSITORY');

export interface CartasRepositoryPort {
  list(
    tipo: CartaEntity['tipo'],
    query?: PaginationQuery,
  ): Promise<PaginatedResult<CartaEntity>>;
  findById(id: string, tipo?: CartaEntity['tipo']): Promise<CartaEntity | null>;
  create(data: CartaWrite): Promise<CartaEntity>;
  update(
    id: string,
    tipo: CartaEntity['tipo'],
    data: Partial<CartaWrite>,
  ): Promise<CartaEntity | null>;
  delete(id: string, tipo: CartaEntity['tipo']): Promise<boolean>;
  listForPublic(
    tipo: CartaEntity['tipo'],
    limit: number,
    direction: 1 | -1,
  ): Promise<CartaEntity[]>;
}
