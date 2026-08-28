import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';
import type {
  UserAccessKey,
  UserRole,
} from '@auth/domain/entities/user.entity';

@Schema({ timestamps: true, collection: 'users' })
export class UserDocument {
  @Prop({ required: true, unique: true, trim: true })
  phoneNumber: string;

  @Prop()
  name?: string;

  @Prop({ required: true, default: 'friends' })
  role: UserRole;

  @Prop({ type: [String], default: [] })
  access: UserAccessKey[];

  @Prop()
  avatarPath?: string;

  @Prop({ enum: ['super_admin'] })
  platformRole?: 'super_admin';

  createdAt: Date;
  updatedAt: Date;
}

export type UserMongoDocument = HydratedDocument<UserDocument>;
export const UserSchema = SchemaFactory.createForClass(UserDocument);
