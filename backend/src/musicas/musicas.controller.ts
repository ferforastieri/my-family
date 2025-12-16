import { Controller, Get, Post, Put, Delete, Body, Param } from '@nestjs/common';
import { MusicasService } from './musicas.service';
import { NewMusicaEspecial } from '@shared/infrastructure/database/schema';

@Controller('musicas')
export class MusicasController {
  constructor(private readonly musicasService: MusicasService) {}

  @Get()
  async findAll() {
    return this.musicasService.findAll();
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.musicasService.findOne(+id);
  }

  @Post()
  async create(@Body() data: NewMusicaEspecial) {
    return this.musicasService.create(data);
  }

  @Put(':id')
  async update(@Param('id') id: string, @Body() data: Partial<NewMusicaEspecial>) {
    return this.musicasService.update(+id, data);
  }

  @Delete(':id')
  async delete(@Param('id') id: string) {
    return this.musicasService.delete(+id);
  }
}

