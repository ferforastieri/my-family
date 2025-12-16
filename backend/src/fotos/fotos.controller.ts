import { Controller, Get, Post, Put, Delete, Body, Param } from '@nestjs/common';
import { FotosService } from './fotos.service';
import { NewFoto } from '@shared/infrastructure/database/schema';

@Controller('fotos')
export class FotosController {
  constructor(private readonly fotosService: FotosService) {}

  @Get()
  async findAll() {
    return this.fotosService.findAll();
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.fotosService.findOne(id);
  }

  @Post()
  async create(@Body() data: NewFoto) {
    return this.fotosService.create(data);
  }

  @Put(':id')
  async update(@Param('id') id: string, @Body() data: Partial<NewFoto>) {
    return this.fotosService.update(id, data);
  }

  @Delete(':id')
  async delete(@Param('id') id: string) {
    return this.fotosService.delete(id);
  }
}


