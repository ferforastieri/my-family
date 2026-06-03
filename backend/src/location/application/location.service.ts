import { BadRequestException, Injectable } from '@nestjs/common';
import type { UserEntity } from '@shared/domain/entities';
import { LocationRepository, LocationUpdateWrite } from '../infrastructure/repositories/location.repository';

@Injectable()
export class LocationService {
  constructor(private locations: LocationRepository) {}

  async update(data: LocationUpdateWrite, user?: UserEntity | null) {
    const latitude = Number(data.latitude);
    const longitude = Number(data.longitude);
    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
      throw new BadRequestException('Localização inválida.');
    }
    return this.locations.create({
      latitude,
      longitude,
      accuracy: toOptionalNumber(data.accuracy),
      altitude: toOptionalNumber(data.altitude),
      speed: toOptionalNumber(data.speed),
      heading: toOptionalNumber(data.heading),
      platform: data.platform ?? 'unknown',
      userId: user?.id ?? data.userId ?? null,
      userName: user?.name || user?.email || data.userName || null,
    });
  }

  latest() {
    return this.locations.latest();
  }
}

function toOptionalNumber(value: unknown) {
  if (value === null || value === undefined) return undefined;
  const numberValue = Number(value);
  return Number.isFinite(numberValue) ? numberValue : undefined;
}

