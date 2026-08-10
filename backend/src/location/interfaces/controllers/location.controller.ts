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
import { AccessGuard } from '@auth/guards/access.guard';
import { JwtAuthGuard } from '@auth/guards/jwt-auth.guard';
import type { UserEntity } from '@auth/domain/entities/user.entity';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import { LocationService } from '../../application/services/location.service';
import { LocationGateway } from '../gateways/location.gateway';
import { LocationPlaceWriteDto, LocationUpdateDto } from '../dto/location.dto';

@Controller('location')
@UseGuards(JwtAuthGuard, AccessGuard)
@Access('localizacao')
export class LocationController {
  constructor(
    private locations: LocationService,
    private realtime: LocationGateway,
  ) {}

  @Post('update')
  async update(
    @Req() request: { user: UserEntity },
    @Body() data: LocationUpdateDto,
  ) {
    const row = await this.locations.update(data, request.user);
    this.realtime.emitLocationUpdated(row);
    return { id: row.id, message: 'Localização atualizada.' };
  }

  @Get('latest')
  latest(@Query() query: PaginationQuery) {
    return this.locations.latest(query);
  }

  @Get('places')
  places() {
    return this.locations.listPlaces();
  }

  @Post('places')
  async createPlace(@Body() data: LocationPlaceWriteDto) {
    const row = await this.locations.createPlace(data);
    this.realtime.emitPlacesChanged(row);
    return { message: 'Local salvo.', ...row };
  }

  @Put('places/:id')
  async updatePlace(
    @Param('id') id: string,
    @Body() data: LocationPlaceWriteDto,
  ) {
    const row = await this.locations.updatePlace(id, data);
    if (row) this.realtime.emitPlacesChanged(row);
    return row ? { message: 'Local atualizado.', ...row } : row;
  }

  @Delete('places/:id')
  async deletePlace(@Param('id') id: string) {
    const ok = await this.locations.deletePlace(id);
    if (ok) this.realtime.emitPlacesChanged({ id });
    return { ok, message: 'Local removido.' };
  }
}
