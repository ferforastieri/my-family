import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

@Schema({ timestamps: true, collection: 'game_words' })
export class GameWordDocument {
  @Prop({ required: true, unique: true })
  word: string;

  @Prop({ default: true })
  active: boolean;

  createdAt: Date;
  updatedAt: Date;
}

export type GameWordMongoDocument = HydratedDocument<GameWordDocument>;
export const GameWordSchema = SchemaFactory.createForClass(GameWordDocument);
