import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  UseGuards,
  Query,
} from '@nestjs/common';
import { Access } from '@auth/decorators/access.decorator';
import { AccessGuard } from '@auth/guards/access.guard';
import { JwtAuthGuard } from '@auth/guards/jwt-auth.guard';
import { MusicasService } from '../../application/services/musicas.service';
import { MusicaWriteDto } from '../dto/musica.dto';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';

@Controller('musicas')
@UseGuards(JwtAuthGuard, AccessGuard)
@Access('playlist')
export class MusicasController {
  constructor(private readonly musicasService: MusicasService) {}

  @Get()
  async findAll(@Query() query: PaginationQuery) {
    return this.musicasService.findAll(query);
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.musicasService.findOne(id);
  }

  @Post()
  async create(@Body() data: MusicaWriteDto) {
    const row = await this.musicasService.create(data);
    return { message: 'Música salva com sucesso.', ...row };
  }

  @Put(':id')
  async update(@Param('id') id: string, @Body() data: Partial<MusicaWriteDto>) {
    const row = await this.musicasService.update(id, data);
    return row ? { message: 'Música atualizada.', ...row } : row;
  }

  @Delete(':id')
  async delete(@Param('id') id: string) {
    return {
      ok: await this.musicasService.delete(id),
      message: 'Música removida.',
    };
  }
}
