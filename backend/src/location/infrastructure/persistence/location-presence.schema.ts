import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';
import { applyTenantScope } from '@tenancy/infrastructure/tenant-scope.plugin';

@Schema({
  timestamps: true,
  collection: 'location_presences',
})
export class LocationPresenceDocument {
  @Prop({ required: true })
  userId: string;

  @Prop({ required: true })
  placeId: string;

  @Prop({ required: true })
  inside: boolean;

  @Prop()
  userName?: string;

  @Prop()
  placeName?: string;

  createdAt: Date;
  updatedAt: Date;
}

export type LocationPresenceMongoDocument =
  HydratedDocument<LocationPresenceDocument>;
export const LocationPresenceSchema = SchemaFactory.createForClass(
  LocationPresenceDocument,
);
LocationPresenceSchema.index(
  { tenantId: 1, userId: 1, placeId: 1 },
  { unique: true },
);
applyTenantScope(LocationPresenceSchema);
