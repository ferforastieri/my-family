import { Injectable } from '@nestjs/common';
import type { UserEntity } from '@shared/domain/entities';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import { JobsService } from '@shared/infrastructure/queue';
import { LocationRepository } from '../infrastructure/repositories/location.repository';
import { locationMapper } from './location.mapper';
import { locationUpdateFactory } from './location.factory';
import { LocationUpdateDto } from '../interfaces/dto/location.dto';

@Injectable()
export class LocationService {
  private lowBatteryAlerts = new Map<string, number>();

  constructor(
    private locations: LocationRepository,
    private jobs: JobsService,
  ) {}

  async update(data: LocationUpdateDto, user?: UserEntity | null) {
    const row = await this.locations.create(
      locationUpdateFactory.create({ dto: data, user }),
    );
    await this.notifyLowBattery(row);
    return locationMapper.toDto(row);
  }

  latest(query?: PaginationQuery) {
    return this.locations.latestByPerson(query).then((page) => ({
      ...page,
      items: page.items.map((item) => locationMapper.toDto(item)),
    }));
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
}
