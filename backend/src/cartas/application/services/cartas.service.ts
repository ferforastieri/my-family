import { Injectable } from '@nestjs/common';
import {
  CartasRepository,
  CartaWrite,
} from '../../infrastructure/repositories/cartas.repository';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import { cartaFactory } from '../factories/carta.factory';
import { cartaMapper } from '../mappers/carta.mapper';
import type { CartaWriteDto } from '../../interfaces/dto/carta.dto';
import type { CartaEntity } from '../../domain/entities/carta.entity';

@Injectable()
export class CartasService {
  constructor(private cartas: CartasRepository) {}

  async findAll(tipo: CartaEntity['tipo'], query?: PaginationQuery) {
    const result = await this.cartas.list(tipo, query);
    return {
      ...result,
      items: result.items.map((item) => cartaMapper.toDto(item)),
    };
  }

  async findOne(id: string, tipo: CartaEntity['tipo']) {
    const item = await this.cartas.findById(id, tipo);
    return item ? cartaMapper.toDto(item) : null;
  }

  async create(tipo: CartaEntity['tipo'], data: CartaWriteDto) {
    return cartaMapper.toDto(
      await this.cartas.create({
        ...(cartaFactory.create(data) as Omit<CartaWrite, 'tipo'>),
        tipo,
      }),
    );
  }

  async update(
    id: string,
    tipo: CartaEntity['tipo'],
    data: Partial<CartaWriteDto>,
  ) {
    const row = await this.cartas.update(id, tipo, cartaFactory.create(data));
    return row ? cartaMapper.toDto(row) : null;
  }

  async delete(id: string, tipo: CartaEntity['tipo']) {
    return this.cartas.delete(id, tipo);
  }
}
