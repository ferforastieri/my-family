import { Injectable } from '@nestjs/common';
import { CartasRepository, CartaWrite } from '../infrastructure/repositories/cartas.repository';

@Injectable()
export class CartasService {
  constructor(private cartas: CartasRepository) {}

  async findAll() {
    return this.cartas.list();
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

