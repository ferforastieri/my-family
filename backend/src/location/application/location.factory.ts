import { BadRequestException } from '@nestjs/common';
import type { UserEntity } from '@shared/domain/entities';
import type { Factory } from '@shared/application/mapper';
import { LocationUpdateDto } from '../interfaces/dto/location.dto';
import type { LocationUpdateWrite } from '../infrastructure/repositories/location.repository';

export type LocationFactoryInput = {
  dto: LocationUpdateDto;
  user?: UserEntity | null;
};

export class LocationUpdateFactory implements Factory<
  LocationFactoryInput,
  LocationUpdateWrite
> {
  create({ dto, user }: LocationFactoryInput): LocationUpdateWrite {
    const latitude = Number(dto.latitude);
    const longitude = Number(dto.longitude);
    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
      throw new BadRequestException('Localização inválida.');
    }

    return {
      latitude,
      longitude,
      accuracy: toOptionalNumber(dto.accuracy),
      altitude: toOptionalNumber(dto.altitude),
      speed: toOptionalNumber(dto.speed),
      heading: toOptionalNumber(dto.heading),
      batteryLevel: normalizeBatteryLevel(dto.batteryLevel),
      isCharging:
        typeof dto.isCharging === 'boolean' ? dto.isCharging : undefined,
      platform: dto.platform ?? 'unknown',
      userId: user?.id ?? dto.userId ?? null,
      userName: user?.name || user?.email || dto.userName || null,
    };
  }
}

export const locationUpdateFactory = new LocationUpdateFactory();

function toOptionalNumber(value: unknown) {
  if (value === null || value === undefined) return undefined;
  const numberValue = Number(value);
  return Number.isFinite(numberValue) ? numberValue : undefined;
}

function normalizeBatteryLevel(value: unknown) {
  const numberValue = toOptionalNumber(value);
  if (numberValue == null) return undefined;
  return Math.max(0, Math.min(100, Math.round(numberValue)));
}
