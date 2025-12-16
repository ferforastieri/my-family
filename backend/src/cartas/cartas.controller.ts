import { Controller, Get, Post, Put, Delete, Body, Param } from '@nestjs/common';
import { CartasService } from './cartas.service';
import { NewCartaDeAmor } from '@shared/infrastructure/database/schema';

@Controller('cartas')
export class CartasController {
  constructor(private readonly cartasService: CartasService) {}

  @Get()
  async findAll() {
    return this.cartasService.findAll();
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.cartasService.findOne(+id);
  }

  @Post()
  async create(@Body() data: NewCartaDeAmor) {
    return this.cartasService.create(data);
  }

  @Put(':id')
  async update(@Param('id') id: string, @Body() data: Partial<NewCartaDeAmor>) {
    return this.cartasService.update(+id, data);
  }

  @Delete(':id')
  async delete(@Param('id') id: string) {
    return this.cartasService.delete(+id);
  }
}


