import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { Access } from '@auth/decorators/access.decorator';
import { AccessGuard } from '@auth/guards/access.guard';
import { JwtAuthGuard } from '@auth/guards/jwt-auth.guard';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import { NotasService } from '../../application/services/notas.service';
import type { NotaWriteDto } from '../dto/nota.dto';

@Controller('notas')
@UseGuards(JwtAuthGuard, AccessGuard)
@Access('notas')
export class NotasController {
  constructor(private readonly notas: NotasService) {}

  @Get()
  list(@Query() query: PaginationQuery) {
    return this.notas.findAll(query);
  }

  @Post()
  async create(@Body() data: NotaWriteDto) {
    const row = await this.notas.create(data);
    return { message: 'Nota salva com sucesso.', ...row };
  }

  @Put(':id')
  async update(@Param('id') id: string, @Body() data: Partial<NotaWriteDto>) {
    const row = await this.notas.update(id, data);
    return row ? { message: 'Nota atualizada.', ...row } : row;
  }

  @Delete(':id')
  async delete(@Param('id') id: string) {
    return { ok: await this.notas.delete(id), message: 'Nota removida.' };
  }
}
