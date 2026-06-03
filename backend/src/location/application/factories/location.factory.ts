import { BadRequestException } from '@nestjs/common';
import type { UserEntity } from '@auth/domain/entities/user.entity';
import type { Factory } from '@shared/application/mapper';
import {
  LocationPlaceWriteDto,
  LocationUpdateDto,
} from '../../interfaces/dto/location.dto';
import type {
  LocationPlaceWrite,
  LocationUpdateWrite,
} from '../../infrastructure/repositories/location.repository';

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

export class LocationPlaceFactory implements Factory<
  LocationPlaceWriteDto,
  LocationPlaceWrite
> {
  create(dto: LocationPlaceWriteDto): LocationPlaceWrite {
    const latitude = Number(dto.latitude);
    const longitude = Number(dto.longitude);
    const radiusMeters = Number(dto.radiusMeters);
    if (!dto.name?.trim()) {
      throw new BadRequestException('Nome do local é obrigatório.');
    }
    if (
      !Number.isFinite(latitude) ||
      !Number.isFinite(longitude) ||
      !Number.isFinite(radiusMeters)
    ) {
      throw new BadRequestException('Dados do local inválidos.');
    }

    return {
      name: dto.name.trim(),
      description: dto.description?.trim(),
      latitude,
      longitude,
      radiusMeters: Math.max(20, Math.min(5000, Math.round(radiusMeters))),
      active: dto.active ?? true,
    };
  }
}

export const locationPlaceFactory = new LocationPlaceFactory();

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
