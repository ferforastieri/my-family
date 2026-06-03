import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

@Schema({
  timestamps: true,
  collection: 'location_places',
})
export class LocationPlaceDocument {
  @Prop({ required: true })
  name: string;

  @Prop()
  description?: string;

  @Prop({ required: true })
  latitude: number;

  @Prop({ required: true })
  longitude: number;

  @Prop({ required: true, default: 120 })
  radiusMeters: number;

  @Prop({ default: true })
  active: boolean;

  createdAt: Date;
  updatedAt: Date;
}

export type LocationPlaceMongoDocument =
  HydratedDocument<LocationPlaceDocument>;
export const LocationPlaceSchema = SchemaFactory.createForClass(
  LocationPlaceDocument,
);
