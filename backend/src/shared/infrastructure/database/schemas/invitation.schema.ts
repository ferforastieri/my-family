import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

@Schema({ timestamps: true, collection: 'invitations' })
export class InvitationDocument {
  @Prop({ required: true, index: true }) tenantId: string;
  @Prop({ required: true, trim: true, index: true }) phoneNumber: string;
  @Prop({ required: true, enum: ['whatsapp', 'sms'] }) channel:
    | 'whatsapp'
    | 'sms';
  @Prop({ required: true, enum: ['admin', 'member'], default: 'member' })
  role: string;
  @Prop({
    required: true,
    enum: ['husband', 'wife', 'children', 'friends'],
    default: 'friends',
  })
  relationship: string;
  @Prop({ type: [String], default: [] }) access: string[];
  @Prop({ required: true, unique: true }) tokenHash: string;
  @Prop({ required: true, index: true }) expiresAt: Date;
  @Prop({
    enum: ['pending', 'accepted', 'revoked'],
    default: 'pending',
    index: true,
  })
  status: string;
  @Prop() invitedBy?: string;
  @Prop() acceptedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}
export type InvitationMongoDocument = HydratedDocument<InvitationDocument>;
export const InvitationSchema =
  SchemaFactory.createForClass(InvitationDocument);
InvitationSchema.index({ tenantId: 1, phoneNumber: 1, status: 1 });
