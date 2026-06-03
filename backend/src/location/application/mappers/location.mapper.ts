import type { Mapper } from '@shared/application/mapper';
import type {
  LocationPlaceEntity,
  LocationUpdateEntity,
} from '@location/domain/entities/location.entity';
import {
  LocationPlaceResponseDto,
  LocationResponseDto,
} from '../../interfaces/dto/location.dto';

export class LocationMapper implements Mapper<
  LocationUpdateEntity,
  LocationResponseDto
> {
  toDto(source: LocationUpdateEntity): LocationResponseDto {
    return {
      id: source.id,
      userId: source.userId ?? null,
      userName: source.userName ?? null,
      latitude: source.latitude,
      longitude: source.longitude,
      accuracy: source.accuracy ?? null,
      altitude: source.altitude ?? null,
      speed: source.speed ?? null,
      heading: source.heading ?? null,
      batteryLevel: source.batteryLevel ?? null,
      isCharging: source.isCharging ?? null,
      platform: source.platform ?? 'unknown',
      createdAt: source.createdAt,
    };
  }
}

export const locationMapper = new LocationMapper();

export class LocationPlaceMapper implements Mapper<
  LocationPlaceEntity,
  LocationPlaceResponseDto
> {
  toDto(source: LocationPlaceEntity): LocationPlaceResponseDto {
    return {
      id: source.id,
      name: source.name,
      description: source.description ?? null,
      latitude: source.latitude,
      longitude: source.longitude,
      radiusMeters: source.radiusMeters,
      active: source.active,
      createdAt: source.createdAt,
      updatedAt: source.updatedAt,
    };
  }
}

export const locationPlaceMapper = new LocationPlaceMapper();
