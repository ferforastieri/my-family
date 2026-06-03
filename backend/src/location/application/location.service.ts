import { BadRequestException, Injectable } from '@nestjs/common';
import type { UserEntity } from '@shared/domain/entities';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import { NotificationsService } from '../../notifications/application/notifications.service';
import { LocationRepository, LocationUpdateWrite } from '../infrastructure/repositories/location.repository';

@Injectable()
export class LocationService {
  private lowBatteryAlerts = new Map<string, number>();

  constructor(
    private locations: LocationRepository,
    private notifications: NotificationsService,
  ) {}

  async update(data: LocationUpdateWrite, user?: UserEntity | null) {
    const latitude = Number(data.latitude);
    const longitude = Number(data.longitude);
    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
      throw new BadRequestException('Localização inválida.');
    }
    const row = await this.locations.create({
      latitude,
      longitude,
      accuracy: toOptionalNumber(data.accuracy),
      altitude: toOptionalNumber(data.altitude),
      speed: toOptionalNumber(data.speed),
      heading: toOptionalNumber(data.heading),
      batteryLevel: normalizeBatteryLevel(data.batteryLevel),
      isCharging: typeof data.isCharging === 'boolean' ? data.isCharging : undefined,
      platform: data.platform ?? 'unknown',
      userId: user?.id ?? data.userId ?? null,
      userName: user?.name || user?.email || data.userName || null,
    });
    await this.notifyLowBattery(row);
    return row;
  }

  latest(query?: PaginationQuery) {
    return this.locations.latestByPerson(query);
  }

  private async notifyLowBattery(row: Awaited<ReturnType<LocationRepository['create']>>) {
    if (row.batteryLevel == null || row.batteryLevel > 20 || row.isCharging === true) return;
    const key = row.userId || row.userName || 'unknown';
    const now = Date.now();
    const last = this.lowBatteryAlerts.get(key) ?? 0;
    if (now - last < 60 * 60 * 1000) return;
    this.lowBatteryAlerts.set(key, now);
    const name = row.userName || 'Alguém';
    await this.notifications.send(
      'Bateria baixa',
      `${name} está com ${row.batteryLevel}% de bateria.`,
      '/localizacao',
    );
  }
}

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
