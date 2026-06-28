import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Access } from '@auth/decorators/access.decorator';
import { AccessGuard } from '@auth/guards/access.guard';
import { CartasService } from '../../application/services/cartas.service';
import { CartaUpdateDto, CartaWriteDto } from '../dto/carta.dto';
import type { UserEntity } from '@auth/domain/entities/user.entity';
import { PaginationMessageDto } from '@shared/interfaces/websocket/websocket.dto';

@Controller('cartas')
@UseGuards(AccessGuard)
@Access('cartas')
export class CartasController {
  constructor(private readonly cartasService: CartasService) {}

  @Get()
  async findAll(@Query() query: PaginationMessageDto) {
    return this.cartasService.findAll('letter', query);
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.cartasService.findOne(id, 'letter');
  }

  @Post()
  async create(
    @Req() request: { user: UserEntity },
    @Body() data: CartaWriteDto,
  ) {
    const row = await this.cartasService.create('letter', data, request.user);
    return { message: 'Texto salvo.', ...row };
  }

  @Put(':id')
  async update(@Param('id') id: string, @Body() data: CartaUpdateDto) {
    const row = await this.cartasService.update(id, 'letter', data);
    return row ? { message: 'Texto atualizado.', ...row } : row;
  }

  @Delete(':id')
  async delete(@Param('id') id: string) {
    return {
      ok: await this.cartasService.delete(id, 'letter'),
      message: 'Texto removido.',
    };
  }
}

@Controller('journey')
@UseGuards(AccessGuard)
@Access('nossaHistoria')
export class JourneyController {
  constructor(private readonly cartasService: CartasService) {}

  @Get()
  async findAll(@Query() query: PaginationMessageDto) {
    return this.cartasService.findAll('journey', query);
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.cartasService.findOne(id, 'journey');
  }

  @Post()
  async create(
    @Req() request: { user: UserEntity },
    @Body() data: CartaWriteDto,
  ) {
    const row = await this.cartasService.create('journey', data, request.user);
    return { message: 'Capítulo salvo.', ...row };
  }

  @Put(':id')
  async update(@Param('id') id: string, @Body() data: CartaUpdateDto) {
    const row = await this.cartasService.update(id, 'journey', data);
    return row ? { message: 'Capítulo atualizado.', ...row } : row;
  }

  @Delete(':id')
  async delete(@Param('id') id: string) {
    return {
      ok: await this.cartasService.delete(id, 'journey'),
      message: 'Capítulo removido.',
    };
  }
}
