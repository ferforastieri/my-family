import { BadRequestException, Injectable } from '@nestjs/common';
import {
  NotaWrite,
  NotasRepository,
} from '../../infrastructure/repositories/notas.repository';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import { notaFactory } from '../factories/nota.factory';
import { notaMapper } from '../mappers/nota.mapper';
import type { NotaWriteDto } from '../../interfaces/dto/nota.dto';

@Injectable()
export class NotasService {
  constructor(private notas: NotasRepository) {}

  async findAll(query?: PaginationQuery) {
    const result = await this.notas.list(query);
    return {
      ...result,
      items: result.items.map((item) => notaMapper.toDto(item)),
    };
  }

  async create(data: NotaWriteDto) {
    return notaMapper.toDto(await this.notas.create(this.validateCreate(data)));
  }

  async update(id: string, data: Partial<NotaWriteDto>) {
    const row = await this.notas.update(id, this.validateUpdate(data));
    return row ? notaMapper.toDto(row) : null;
  }

  async delete(id: string) {
    return this.notas.delete(id);
  }

  private validateCreate(data: Partial<NotaWriteDto>): NotaWrite {
    const normalized = notaFactory.create(data);
    if (!normalized.titulo || !normalized.conteudo) {
      throw new BadRequestException('Informe título e conteúdo da nota.');
    }
    return normalized as NotaWrite;
  }

  private validateUpdate(data: Partial<NotaWriteDto>): Partial<NotaWrite> {
    const normalized = notaFactory.create(data);
    if (
      Object.prototype.hasOwnProperty.call(data, 'titulo') &&
      !normalized.titulo
    ) {
      throw new BadRequestException('Título não pode ficar vazio.');
    }
    if (
      Object.prototype.hasOwnProperty.call(data, 'conteudo') &&
      !normalized.conteudo
    ) {
      throw new BadRequestException('Conteúdo não pode ficar vazio.');
    }
    return normalized;
  }
}
