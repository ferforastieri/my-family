import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

@Schema({
  timestamps: { createdAt: true, updatedAt: false },
  collection: 'game_completions',
})
export class GameCompletionDocument {
  @Prop({ required: true })
  game: string;

  @Prop({ required: true })
  playerName: string;

  @Prop()
  userId?: string;

  @Prop()
  score?: number;

  @Prop()
  total?: number;

  createdAt: Date;
}

export type GameCompletionMongoDocument =
  HydratedDocument<GameCompletionDocument>;
export const GameCompletionSchema = SchemaFactory.createForClass(
  GameCompletionDocument,
);
