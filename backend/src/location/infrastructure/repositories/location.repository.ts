import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  LocationUpdateDocument,
  LocationUpdateMongoDocument,
} from '@shared/infrastructure/database/schemas';
import {
  cleanUndefined,
  normalizePagination,
  paginated,
  PaginatedResult,
  PaginationQuery,
  toId,
} from '@shared/infrastructure/database/mongo.utils';
import type { LocationUpdateEntity } from '@location/domain/entities/location.entity';

export type LocationUpdateWrite = Pick<
  LocationUpdateEntity,
  'latitude' | 'longitude'
> &
  Partial<
    Pick<
      LocationUpdateEntity,
      | 'userId'
      | 'userName'
      | 'accuracy'
      | 'altitude'
      | 'speed'
      | 'heading'
      | 'batteryLevel'
      | 'isCharging'
      | 'platform'
    >
  >;

@Injectable()
export class LocationRepository {
  constructor(
    @InjectModel(LocationUpdateDocument.name)
    private model: Model<LocationUpdateMongoDocument>,
  ) {}

  private toEntity(
    doc: LocationUpdateMongoDocument | null,
  ): LocationUpdateEntity | null {
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

  async latestByPerson(
    query?: PaginationQuery,
  ): Promise<PaginatedResult<LocationUpdateEntity>> {
    const { page, limit, skip } = normalizePagination(query, {
      page: 1,
      limit: 50,
      maxLimit: 100,
    });
    const [result] = await this.model.aggregate([
      { $sort: { createdAt: -1 } },
      {
        $group: {
          _id: {
            $ifNull: [
              '$userId',
              {
                $ifNull: [
                  '$userName',
                  {
                    $concat: [
                      { $toString: '$latitude' },
                      ',',
                      { $toString: '$longitude' },
                    ],
                  },
                ],
              },
            ],
          },
          row: { $first: '$$ROOT' },
        },
      },
      { $replaceRoot: { newRoot: '$row' } },
      { $sort: { createdAt: -1 } },
      {
        $facet: {
          items: [{ $skip: skip }, { $limit: limit }],
          total: [{ $count: 'count' }],
        },
      },
    ]);
    const rows = result?.items ?? [];
    const total = result?.total?.[0]?.count ?? 0;
    return paginated(
      rows.map((row: LocationUpdateMongoDocument) => this.toEntity(row)!),
      total,
      page,
      limit,
    );
  }
}
