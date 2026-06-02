import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Schema as MongooseSchema } from 'mongoose';
import { UserDocument } from './user.schema';

@Schema({ timestamps: { createdAt: true, updatedAt: false }, collection: 'password_resets' })
export class PasswordResetDocument {
  @Prop({ type: MongooseSchema.Types.ObjectId, required: true, ref: UserDocument.name })
  userId: string;

  @Prop({ required: true, unique: true })
  token: string;

  @Prop({ required: true })
  expiresAt: Date;

  @Prop()
  used?: Date;

  createdAt: Date;
}

export type PasswordResetMongoDocument = HydratedDocument<PasswordResetDocument>;
export const PasswordResetSchema = SchemaFactory.createForClass(PasswordResetDocument);

