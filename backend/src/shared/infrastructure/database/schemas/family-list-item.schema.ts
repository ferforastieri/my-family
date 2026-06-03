import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

@Schema({ timestamps: true, collection: 'family_list_items' })
export class FamilyListItemDocument {
  @Prop({ required: true })
  listId: string;

  @Prop({ required: true, trim: true })
  text: string;

  @Prop({ default: false })
  checked: boolean;

  @Prop()
  createdBy?: string;

  createdAt: Date;
  updatedAt: Date;
}

export type FamilyListItemMongoDocument =
  HydratedDocument<FamilyListItemDocument>;
export const FamilyListItemSchema = SchemaFactory.createForClass(
  FamilyListItemDocument,
);
