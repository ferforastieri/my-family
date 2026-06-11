import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

@Schema({ timestamps: true, collection: 'mini_game_configs' })
export class MiniGameConfigDocument {
  @Prop({
    required: true,
    unique: true,
    enum: ['memory_match', 'love_order', 'this_or_that'],
  })
  type: 'memory_match' | 'love_order' | 'this_or_that';

  @Prop({ required: true })
  title: string;

  @Prop({ default: '' })
  instructions: string;

  @Prop({ type: [String], default: [] })
  items: string[];

  @Prop({ default: true })
  active: boolean;

  createdAt: Date;
  updatedAt: Date;
}

export type MiniGameConfigMongoDocument =
  HydratedDocument<MiniGameConfigDocument>;
export const MiniGameConfigSchema = SchemaFactory.createForClass(
  MiniGameConfigDocument,
);
