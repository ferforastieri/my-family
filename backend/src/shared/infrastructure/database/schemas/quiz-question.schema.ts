import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

@Schema({ timestamps: true, collection: 'quiz_questions' })
export class QuizQuestionDocument {
  @Prop({ required: true })
  question: string;

  @Prop({ type: [String], required: true })
  options: string[];

  @Prop({ required: true })
  correctIndex: number;

  @Prop({ default: true })
  active: boolean;

  createdAt: Date;
  updatedAt: Date;
}

export type QuizQuestionMongoDocument = HydratedDocument<QuizQuestionDocument>;
export const QuizQuestionSchema = SchemaFactory.createForClass(QuizQuestionDocument);
