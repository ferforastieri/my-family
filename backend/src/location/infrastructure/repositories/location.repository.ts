import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  LocationPlaceDocument,
  LocationPlaceMongoDocument,
} from '../persistence/location-place.schema';
import {
  LocationPresenceDocument,
  LocationPresenceMongoDocument,
} from '../persistence/location-presence.schema';
import {
  LocationUpdateDocument,
  LocationUpdateMongoDocument,
} from '../persistence/location-update.schema';
import {
  cleanUndefined,
  normalizePagination,
  paginated,
  PaginatedResult,
  PaginationQuery,
  toId,
} from '@shared/infrastructure/database/mongo.utils';
import type {
  LocationPlaceEntity,
  LocationPresenceEntity,
  LocationUpdateEntity,
} from '@location/domain/entities/location.entity';

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

export type LocationPlaceWrite = Pick<
  LocationPlaceEntity,
  'name' | 'latitude' | 'longitude' | 'radiusMeters'
> &
  Partial<Pick<LocationPlaceEntity, 'description' | 'active'>>;

@Injectable()
export class LocationRepository {
  constructor(
    @InjectModel(LocationUpdateDocument.name)
    private model: Model<LocationUpdateMongoDocument>,
    @InjectModel(LocationPlaceDocument.name)
    private placeModel: Model<LocationPlaceMongoDocument>,
    @InjectModel(LocationPresenceDocument.name)
    private presenceModel: Model<LocationPresenceMongoDocument>,
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

  private toPlaceEntity(
    doc: LocationPlaceMongoDocument | null,
  ): LocationPlaceEntity | null {
    if (!doc) return null;
    return {
      id: toId(doc),
      name: doc.name,
      description: doc.description ?? null,
      latitude: doc.latitude,
      longitude: doc.longitude,
      radiusMeters: doc.radiusMeters,
      active: doc.active !== false,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    };
  }

  private toPresenceEntity(
    doc: LocationPresenceMongoDocument | null,
  ): LocationPresenceEntity | null {
    if (!doc) return null;
    return {
      id: toId(doc),
      userId: doc.userId,
      placeId: doc.placeId,
      inside: doc.inside,
      userName: doc.userName ?? null,
      placeName: doc.placeName ?? null,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    };
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
      {
        $match: {
          userId: { $nin: [null, ''] },
          platform: { $in: ['android', 'ios'] },
        },
      },
      { $sort: { createdAt: -1 } },
      {
        $group: {
          _id: '$userId',
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

  async listPlaces() {
    const docs = await this.placeModel
      .find()
      .sort({ name: 1, createdAt: -1 })
      .exec();
    return docs.map((doc) => this.toPlaceEntity(doc)!);
  }

  async listActivePlaces() {
    const docs = await this.placeModel
      .find({ active: true })
      .sort({ name: 1 })
      .exec();
    return docs.map((doc) => this.toPlaceEntity(doc)!);
  }

  async createPlace(data: LocationPlaceWrite) {
    return this.toPlaceEntity(
      await this.placeModel.create(cleanUndefined(data)),
    )!;
  }

  async updatePlace(id: string, data: Partial<LocationPlaceWrite>) {
    return this.toPlaceEntity(
      await this.placeModel
        .findByIdAndUpdate(id, { $set: cleanUndefined(data) }, { new: true })
        .exec(),
    );
  }

  async deletePlace(id: string) {
    const deleted = await this.placeModel.findByIdAndDelete(id).exec();
    if (deleted) await this.presenceModel.deleteMany({ placeId: id }).exec();
    return !!deleted;
  }

  async findPresence(userId: string, placeId: string) {
    return this.toPresenceEntity(
      await this.presenceModel.findOne({ userId, placeId }).exec(),
    );
  }

  async upsertPresence(data: {
    userId: string;
    userName?: string | null;
    placeId: string;
    placeName: string;
    inside: boolean;
  }) {
    return this.toPresenceEntity(
      await this.presenceModel
        .findOneAndUpdate(
          { userId: data.userId, placeId: data.placeId },
          {
            $set: {
              inside: data.inside,
              userName: data.userName ?? undefined,
              placeName: data.placeName,
            },
          },
          { upsert: true, new: true },
        )
        .exec(),
    )!;
  }
}
