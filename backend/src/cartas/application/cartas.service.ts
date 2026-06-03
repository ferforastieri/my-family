import { Injectable } from '@nestjs/common';
import { CartasRepository, CartaWrite } from '../infrastructure/repositories/cartas.repository';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';

@Injectable()
export class CartasService {
  constructor(private cartas: CartasRepository) {}

  async findAll(query?: PaginationQuery) {
    return this.cartas.list(query);
  }

  async findOne(id: string) {
    return this.cartas.findById(id);
  }

  async create(data: CartaWrite) {
    return this.cartas.create(data);
  }

  async update(id: string, data: Partial<CartaWrite>) {
    return this.cartas.update(id, data);
  }

  async delete(id: string) {
    return this.cartas.delete(id);
  }
}
