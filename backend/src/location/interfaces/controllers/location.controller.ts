import {
  Body,
  Controller,
  Delete,
  ForbiddenException,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Access } from '@auth/decorators/access.decorator';
import { AccessGuard } from '@auth/guards/access.guard';
import {
  isAdminRole,
  type UserEntity,
} from '@auth/domain/entities/user.entity';
import { LocationService } from '../../application/services/location.service';
import { LocationGateway } from '../gateways/location.gateway';
import {
  LocationPlaceWriteDto,
  LocationUpdateDto,
} from '../dto/location.dto';
import { PaginationMessageDto } from '@shared/interfaces/websocket/websocket.dto';

@Controller('location')
@UseGuards(AccessGuard)
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
    const user = request.user;
    if (!isAdminRole(user.role) && !user.access.includes('localizacao')) {
      throw new ForbiddenException('Você não tem acesso a localização.');
    }
    const row = await this.locations.update(data, user);
    this.realtime.emitLocationUpdated(row);
    return { id: row.id };
  }

  @Get('latest')
  async latest(@Query() query: PaginationMessageDto) {
    return this.locations.latest(query);
  }

  @Get('places')
  async places() {
    return this.locations.listPlaces();
  }

  @Post('places')
  async createPlace(@Body() data: LocationPlaceWriteDto) {
    const row = await this.locations.createPlace(data);
    this.realtime.emitPlacesChanged(row);
    return { message: 'Local salvo.', ...row };
  }

  @Patch('places/:id')
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
