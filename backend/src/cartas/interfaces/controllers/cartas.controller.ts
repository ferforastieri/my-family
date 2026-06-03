import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
} from '@nestjs/common';
import { CartasService } from '../../application/services/cartas.service';
import type { CartaWriteDto } from '../dto/carta.dto';

@Controller('cartas')
export class CartasController {
  constructor(private readonly cartasService: CartasService) {}

  @Get()
  async findAll() {
    return this.cartasService.findAll();
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.cartasService.findOne(id);
  }

  @Post()
  async create(@Body() data: CartaWriteDto) {
    const row = await this.cartasService.create(data);
    return { message: 'Texto salvo.', ...row };
  }

  @Put(':id')
  async update(@Param('id') id: string, @Body() data: Partial<CartaWriteDto>) {
    const row = await this.cartasService.update(id, data);
    return row ? { message: 'Texto atualizado.', ...row } : row;
  }

  @Delete(':id')
  async delete(@Param('id') id: string) {
    return {
      ok: await this.cartasService.delete(id),
      message: 'Texto removido.',
    };
  }
}
