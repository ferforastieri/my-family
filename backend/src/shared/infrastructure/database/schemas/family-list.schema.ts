import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

@Schema({ timestamps: true, collection: 'family_lists' })
export class FamilyListDocument {
  @Prop({ required: true, trim: true })
  title: string;

  @Prop()
  description?: string;

  @Prop()
  createdBy?: string;

  createdAt: Date;
  updatedAt: Date;
}

export type FamilyListMongoDocument = HydratedDocument<FamilyListDocument>;
export const FamilyListSchema = SchemaFactory.createForClass(FamilyListDocument);

