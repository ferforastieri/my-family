import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

@Schema({ timestamps: { createdAt: true, updatedAt: false }, collection: 'location_updates' })
export class LocationUpdateDocument {
  @Prop()
  userId?: string;

  @Prop()
  userName?: string;

  @Prop({ required: true })
  latitude: number;

  @Prop({ required: true })
  longitude: number;

  @Prop()
  accuracy?: number;

  @Prop()
  altitude?: number;

  @Prop()
  speed?: number;

  @Prop()
  heading?: number;

  @Prop()
  batteryLevel?: number;

  @Prop()
  isCharging?: boolean;

  @Prop({ default: 'unknown', enum: ['web', 'android', 'ios', 'unknown'] })
  platform?: 'web' | 'android' | 'ios' | 'unknown';

  createdAt: Date;
}

export type LocationUpdateMongoDocument = HydratedDocument<LocationUpdateDocument>;
export const LocationUpdateSchema = SchemaFactory.createForClass(LocationUpdateDocument);
