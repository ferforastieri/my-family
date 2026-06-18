import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

@Schema({ timestamps: true, collection: 'home_settings' })
export class HomeSettingsDocument {
  @Prop({ required: true, default: 'home' })
  key: string;

  @Prop({ type: [Object], required: true, default: [] })
  events: Array<{
    title: string;
    icon: string;
    date: Date;
    message: string;
    countDirection?: 'forward' | 'backward';
    hidden?: boolean;
  }>;

  @Prop({ type: [String], required: true, default: [] })
  galleryImages: string[];

  @Prop()
  galleryOrder?: number;

  createdAt?: Date;
  updatedAt?: Date;
}

export type HomeSettingsMongoDocument = HydratedDocument<HomeSettingsDocument>;

export const HomeSettingsSchema =
  SchemaFactory.createForClass(HomeSettingsDocument);

HomeSettingsSchema.index({ key: 1 }, { unique: true });
