import {
  Body,
  Controller,
  ForbiddenException,
  Post,
  Req,
} from '@nestjs/common';
import {
  isAdminRole,
  type UserEntity,
} from '@auth/domain/entities/user.entity';
import { LocationService } from '../../application/services/location.service';
import { LocationGateway } from '../gateways/location.gateway';
import { LocationUpdateDto } from '../dto/location.dto';

@Controller('location')
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
}
