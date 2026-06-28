import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { Access } from '@auth/decorators/access.decorator';
import { AccessGuard } from '@auth/guards/access.guard';
import { PaginationMessageDto } from '@shared/interfaces/websocket/websocket.dto';
import { NotasService } from '../../application/services/notas.service';
import { NotaUpdateDto, NotaWriteDto } from '../dto/nota.dto';

@Controller('notas')
@UseGuards(AccessGuard)
@Access('notas')
export class NotasController {
  constructor(private readonly notas: NotasService) {}

  @Get()
  findAll(@Query() query: PaginationMessageDto) {
    return this.notas.findAll(query);
  }

  @Post()
  async create(@Body() body: NotaWriteDto) {
    const row = await this.notas.create(body);
    return { message: 'Nota salva com sucesso.', ...row };
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() body: NotaUpdateDto) {
    const row = await this.notas.update(id, body);
    return row ? { message: 'Nota atualizada.', ...row } : row;
  }

  @Delete(':id')
  async delete(@Param('id') id: string) {
    return { ok: await this.notas.delete(id), message: 'Nota removida.' };
  }
}
