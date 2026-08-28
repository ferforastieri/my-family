import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

@Schema({ timestamps: true, collection: 'phone_challenges' })
export class PhoneChallengeDocument {
  @Prop({ required: true, index: true }) phoneNumber: string;
  @Prop({ required: true }) codeHash: string;
  @Prop({ required: true, enum: ['whatsapp', 'sms'] }) channel:
    | 'whatsapp'
    | 'sms';
  @Prop({ required: true, default: 0 }) attempts: number;
  @Prop({ required: true }) expiresAt: Date;
  @Prop() consumedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

export type PhoneChallengeMongoDocument =
  HydratedDocument<PhoneChallengeDocument>;
export const PhoneChallengeSchema = SchemaFactory.createForClass(
  PhoneChallengeDocument,
);
PhoneChallengeSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });
PhoneChallengeSchema.index({ phoneNumber: 1, consumedAt: 1, createdAt: -1 });
