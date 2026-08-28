import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

@Schema({ timestamps: true, collection: 'auth_sessions' })
export class AuthSessionDocument {
  @Prop({ required: true, index: true }) userId: string;
  @Prop({ required: true, unique: true }) tokenHash: string;
  @Prop({ index: true }) tenantId?: string;
  @Prop() userAgent?: string;
  @Prop({ required: true }) expiresAt: Date;
  @Prop() revokedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}
export type AuthSessionMongoDocument = HydratedDocument<AuthSessionDocument>;
export const AuthSessionSchema =
  SchemaFactory.createForClass(AuthSessionDocument);
AuthSessionSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });
