import { Inject, Injectable } from '@nestjs/common';
import type { PaginationQuery } from '@shared/application/pagination';
import { cartaFactory } from '../factories/carta.factory';
import type { CartaEntity } from '../../domain/entities/carta.entity';
import type { UserEntity } from '@auth/domain/entities/user.entity';
import type { CartaWriteInput } from '../models/carta.models';
import {
  CARTAS_REPOSITORY,
  type CartasRepositoryPort,
} from '../ports/cartas.repository.port';
import {
  CARTA_NOTIFIER,
  type CartaNotifierPort,
} from '../ports/carta-notifier.port';

@Injectable()
export class CartasService {
  constructor(
    @Inject(CARTAS_REPOSITORY)
    private readonly cartas: CartasRepositoryPort,
    @Inject(CARTA_NOTIFIER)
    private readonly notifier: CartaNotifierPort,
  ) {}

  async findAll(tipo: CartaEntity['tipo'], query?: PaginationQuery) {
    const result = await this.cartas.list(tipo, query);
    return result;
  }

  async findOne(id: string, tipo: CartaEntity['tipo']) {
    const item = await this.cartas.findById(id, tipo);
    return item;
  }

  async create(
    tipo: CartaEntity['tipo'],
    data: CartaWriteInput,
    author?: UserEntity | null,
  ) {
    const normalized = cartaFactory.create(data);
    const row = await this.cartas.create({
      titulo: normalized.titulo,
      conteudo: normalized.conteudo,
      data: normalized.data,
      tipo,
    });
    if (tipo === 'letter') {
      const authorName =
        author?.name?.trim() || author?.email?.split('@')[0] || 'Alguém';
      await this.notifier.letterCreated(row.titulo, authorName);
    }
    return row;
  }

  async update(
    id: string,
    tipo: CartaEntity['tipo'],
    data: Partial<CartaWriteInput>,
  ) {
    const row = await this.cartas.update(id, tipo, cartaFactory.create(data));
    return row;
  }

  async delete(id: string, tipo: CartaEntity['tipo']) {
    return this.cartas.delete(id, tipo);
  }

  listForPublic(tipo: CartaEntity['tipo'], limit: number, direction: 1 | -1) {
    return this.cartas.listForPublic(tipo, limit, direction);
  }
}
