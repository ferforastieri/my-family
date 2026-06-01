import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Schema as MongooseSchema } from 'mongoose';
import type { UserRole } from '@shared/domain/entities';

@Schema({ timestamps: true, collection: 'users' })
export class UserDocument {
  @Prop({ required: true, unique: true, lowercase: true, trim: true })
  email: string;

  @Prop()
  passwordHash?: string;

  @Prop()
  name?: string;

  @Prop({ required: true, default: 'friend' })
  role: UserRole;

  @Prop()
  avatarPath?: string;

  createdAt: Date;
  updatedAt: Date;
}

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

@Schema({ timestamps: true, collection: 'fotos' })
export class FotoDocument {
  @Prop({ required: true })
  url: string;

  @Prop()
  texto?: string;

  @Prop({ required: true, enum: ['imagem', 'video'] })
  tipo: 'imagem' | 'video';

  createdAt: Date;
  updatedAt: Date;
}

@Schema({ timestamps: true, collection: 'musicas' })
export class MusicaDocument {
  @Prop({ required: true })
  titulo: string;

  @Prop({ required: true })
  artista: string;

  @Prop({ required: true })
  linkSpotify: string;

  @Prop()
  descricao?: string;

  @Prop({ required: true })
  momento: string;

  @Prop({ default: Date.now })
  data: Date;

  createdAt: Date;
  updatedAt: Date;
}

@Schema({ timestamps: true, collection: 'cartas' })
export class CartaDocument {
  @Prop({ required: true })
  titulo: string;

  @Prop({ required: true })
  conteudo: string;

  @Prop({ default: Date.now })
  data: Date;

  createdAt: Date;
  updatedAt: Date;
}

@Schema({ timestamps: { createdAt: true, updatedAt: false }, collection: 'notifications' })
export class NotificationDocument {
  @Prop({ required: true })
  title: string;

  @Prop({ required: true, default: '' })
  body: string;

  @Prop({ required: true, default: '/' })
  url: string;

  @Prop()
  icon?: string;

  createdAt: Date;
}

@Schema({ timestamps: { createdAt: true, updatedAt: false }, collection: 'push_subscriptions' })
export class PushSubscriptionDocument {
  @Prop({ required: true, unique: true })
  endpoint: string;

  @Prop({ type: Object, required: true })
  keys: { p256dh: string; auth: string };

  @Prop()
  userAgent?: string;

  createdAt: Date;
}

export type UserMongoDocument = HydratedDocument<UserDocument>;
export type PasswordResetMongoDocument = HydratedDocument<PasswordResetDocument>;
export type FotoMongoDocument = HydratedDocument<FotoDocument>;
export type MusicaMongoDocument = HydratedDocument<MusicaDocument>;
export type CartaMongoDocument = HydratedDocument<CartaDocument>;
export type NotificationMongoDocument = HydratedDocument<NotificationDocument>;
export type PushSubscriptionMongoDocument = HydratedDocument<PushSubscriptionDocument>;

export const UserSchema = SchemaFactory.createForClass(UserDocument);
export const PasswordResetSchema = SchemaFactory.createForClass(PasswordResetDocument);
export const FotoSchema = SchemaFactory.createForClass(FotoDocument);
export const MusicaSchema = SchemaFactory.createForClass(MusicaDocument);
export const CartaSchema = SchemaFactory.createForClass(CartaDocument);
export const NotificationSchema = SchemaFactory.createForClass(NotificationDocument);
export const PushSubscriptionSchema = SchemaFactory.createForClass(PushSubscriptionDocument);

export const mongoModels = [
  { name: UserDocument.name, schema: UserSchema },
  { name: PasswordResetDocument.name, schema: PasswordResetSchema },
  { name: FotoDocument.name, schema: FotoSchema },
  { name: MusicaDocument.name, schema: MusicaSchema },
  { name: CartaDocument.name, schema: CartaSchema },
  { name: NotificationDocument.name, schema: NotificationSchema },
  { name: PushSubscriptionDocument.name, schema: PushSubscriptionSchema },
];
