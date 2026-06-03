import { Injectable } from '@nestjs/common';
import {
  CartasRepository,
  CartaWrite,
} from '../../infrastructure/repositories/cartas.repository';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import { cartaFactory } from '../factories/carta.factory';
import { cartaMapper } from '../mappers/carta.mapper';
import type { CartaWriteDto } from '../../interfaces/dto/carta.dto';

@Injectable()
export class CartasService {
  constructor(private cartas: CartasRepository) {}

  async findAll(query?: PaginationQuery) {
    const result = await this.cartas.list(query);
    return {
      ...result,
      items: result.items.map((item) => cartaMapper.toDto(item)),
    };
  }

  async findOne(id: string) {
    const item = await this.cartas.findById(id);
    return item ? cartaMapper.toDto(item) : null;
  }

  async create(data: CartaWriteDto) {
    return cartaMapper.toDto(
      await this.cartas.create(cartaFactory.create(data) as CartaWrite),
    );
  }

  async update(id: string, data: Partial<CartaWriteDto>) {
    const row = await this.cartas.update(id, cartaFactory.create(data));
    return row ? cartaMapper.toDto(row) : null;
  }

  async delete(id: string) {
    return this.cartas.delete(id);
  }
}
