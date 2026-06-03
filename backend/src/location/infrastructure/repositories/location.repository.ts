import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { LocationUpdateDocument, LocationUpdateMongoDocument } from '@shared/infrastructure/database/schemas';
import { cleanUndefined, toId } from '@shared/infrastructure/database/mongo.utils';
import type { LocationUpdateEntity } from '@shared/domain/entities';

export type LocationUpdateWrite = Pick<LocationUpdateEntity, 'latitude' | 'longitude'> &
  Partial<
    Pick<
      LocationUpdateEntity,
      'userId' | 'userName' | 'accuracy' | 'altitude' | 'speed' | 'heading' | 'batteryLevel' | 'isCharging' | 'platform'
    >
  >;

@Injectable()
export class LocationRepository {
  constructor(@InjectModel(LocationUpdateDocument.name) private model: Model<LocationUpdateMongoDocument>) {}

  private toEntity(doc: LocationUpdateMongoDocument | null): LocationUpdateEntity | null {
    if (!doc) return null;
    return {
      id: toId(doc),
      userId: doc.userId ?? null,
      userName: doc.userName ?? null,
      latitude: doc.latitude,
      longitude: doc.longitude,
      accuracy: doc.accuracy ?? null,
      altitude: doc.altitude ?? null,
      speed: doc.speed ?? null,
      heading: doc.heading ?? null,
      batteryLevel: doc.batteryLevel ?? null,
      isCharging: doc.isCharging ?? null,
      platform: doc.platform ?? 'unknown',
      createdAt: doc.createdAt,
    };
  }

  async create(data: LocationUpdateWrite) {
    return this.toEntity(await this.model.create(cleanUndefined(data)))!;
  }

  async latest(limit = 50) {
    return (await this.model.find().sort({ createdAt: -1 }).limit(limit).exec()).map((doc) => this.toEntity(doc)!);
  }

  async latestByPerson(limit = 100) {
    const rows = await this.latest(limit);
    const seen = new Set<string>();
    return rows.filter((row) => {
      const key = row.userId || row.userName || `${row.latitude},${row.longitude}`;
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    });
  }
}
