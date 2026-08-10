import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Access } from '@auth/decorators/access.decorator';
import type { UserEntity } from '@auth/domain/entities/user.entity';
import { AccessGuard } from '@auth/guards/access.guard';
import { JwtAuthGuard } from '@auth/guards/jwt-auth.guard';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import { CartasService } from '../../application/services/cartas.service';
import type { CartaWriteDto } from '../dto/carta.dto';

@Controller('journey')
@UseGuards(JwtAuthGuard, AccessGuard)
@Access('nossaHistoria')
export class JourneyController {
  constructor(private readonly cartas: CartasService) {}

  @Get()
  list(@Query() query: PaginationQuery) {
    return this.cartas.findAll('journey', query);
  }

  @Post()
  async create(
    @Req() request: { user: UserEntity },
    @Body() data: CartaWriteDto,
  ) {
    const row = await this.cartas.create('journey', data, request.user);
    return { message: 'Capítulo salvo.', ...row };
  }

  @Put(':id')
  async update(@Param('id') id: string, @Body() data: Partial<CartaWriteDto>) {
    const row = await this.cartas.update(id, 'journey', data);
    return row ? { message: 'Capítulo atualizado.', ...row } : row;
  }

  @Delete(':id')
  async delete(@Param('id') id: string) {
    return {
      ok: await this.cartas.delete(id, 'journey'),
      message: 'Capítulo removido.',
    };
  }
}
