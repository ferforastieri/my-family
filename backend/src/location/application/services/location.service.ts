import { BadRequestException, Injectable } from '@nestjs/common';
import type { UserEntity } from '@auth/domain/entities/user.entity';
import { NotificationsService } from '@notifications/application/services/notifications.service';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import { JobsService } from '@shared/infrastructure/queue';
import { LocationRepository } from '../../infrastructure/repositories/location.repository';
import {
  locationMapper,
  locationPlaceMapper,
} from '../mappers/location.mapper';
import {
  locationPlaceFactory,
  locationUpdateFactory,
} from '../factories/location.factory';
import {
  LocationPlaceWriteDto,
  LocationUpdateDto,
} from '../../interfaces/dto/location.dto';

@Injectable()
export class LocationService {
  private lowBatteryAlerts = new Map<string, number>();

  constructor(
    private locations: LocationRepository,
    private jobs: JobsService,
    private notifications: NotificationsService,
  ) {}

  async update(data: LocationUpdateDto, user?: UserEntity | null) {
    if (data.platform === 'web') {
      throw new BadRequestException('Localização web não é rastreada.');
    }
    const row = await this.locations.create(
      locationUpdateFactory.create({ dto: data, user }),
    );
    await this.notifyLowBattery(row);
    await this.notifyPlaceTransitions(row);
    return locationMapper.toDto(row);
  }

  latest(query?: PaginationQuery) {
    return this.locations.latestByPerson(query).then((page) => ({
      ...page,
      items: page.items.map((item) => locationMapper.toDto(item)),
    }));
  }

  async listPlaces() {
    return (await this.locations.listPlaces()).map((place) =>
      locationPlaceMapper.toDto(place),
    );
  }

  async createPlace(data: LocationPlaceWriteDto) {
    return locationPlaceMapper.toDto(
      await this.locations.createPlace(locationPlaceFactory.create(data)),
    );
  }

  async updatePlace(id: string, data: LocationPlaceWriteDto) {
    const row = await this.locations.updatePlace(
      id,
      locationPlaceFactory.create(data),
    );
    return row ? locationPlaceMapper.toDto(row) : null;
  }

  async deletePlace(id: string) {
    return this.locations.deletePlace(id);
  }

  private async notifyLowBattery(
    row: Awaited<ReturnType<LocationRepository['create']>>,
  ) {
    if (
      row.batteryLevel == null ||
      row.batteryLevel > 20 ||
      row.isCharging === true
    )
      return;
    const key = row.userId || row.userName || 'unknown';
    const now = Date.now();
    const last = this.lowBatteryAlerts.get(key) ?? 0;
    if (now - last < 60 * 60 * 1000) return;
    this.lowBatteryAlerts.set(key, now);
    const name = row.userName || 'Alguém';
    await this.jobs.enqueueLowBatteryAlert({
      name,
      batteryLevel: row.batteryLevel,
    });
  }

  private async notifyPlaceTransitions(
    row: Awaited<ReturnType<LocationRepository['create']>>,
  ) {
    if (!row.userId) return;
    const places = await this.locations.listActivePlaces();
    for (const place of places) {
      const inside =
        distanceMeters(
          row.latitude,
          row.longitude,
          place.latitude,
          place.longitude,
        ) <= place.radiusMeters;
      const previous = await this.locations.findPresence(row.userId, place.id);
      if (previous?.inside === inside) continue;

      await this.locations.upsertPresence({
        userId: row.userId,
        userName: row.userName,
        placeId: place.id,
        placeName: place.name,
        inside,
      });

      if (previous == null) continue;

      const name = row.userName || 'Alguém';
      await this.notifications.send(
        'Localização da família',
        inside
          ? `${name} chegou em ${place.name}.`
          : `${name} saiu de ${place.name}.`,
        '/localizacao',
      );
    }
  }
}

function distanceMeters(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number,
) {
  const earthRadius = 6371000;
  const phi1 = toRadians(lat1);
  const phi2 = toRadians(lat2);
  const deltaPhi = toRadians(lat2 - lat1);
  const deltaLambda = toRadians(lon2 - lon1);
  const a =
    Math.sin(deltaPhi / 2) ** 2 +
    Math.cos(phi1) * Math.cos(phi2) * Math.sin(deltaLambda / 2) ** 2;
  return earthRadius * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function toRadians(value: number) {
  return (value * Math.PI) / 180;
}
