import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
} from '@nestjs/common';
import { MusicasService } from '../../application/musicas.service';
import type { MusicaWriteDto } from '../dto/musica.dto';

@Controller('musicas')
export class MusicasController {
  constructor(private readonly musicasService: MusicasService) {}

  @Get()
  async findAll() {
    return this.musicasService.findAll();
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.musicasService.findOne(id);
  }

  @Post()
  async create(@Body() data: MusicaWriteDto) {
    return this.musicasService.create(data);
  }

  @Put(':id')
  async update(@Param('id') id: string, @Body() data: Partial<MusicaWriteDto>) {
    return this.musicasService.update(id, data);
  }

  @Delete(':id')
  async delete(@Param('id') id: string) {
    return this.musicasService.delete(id);
  }
}
