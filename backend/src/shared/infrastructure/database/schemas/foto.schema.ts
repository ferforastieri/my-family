import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

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

export type FotoMongoDocument = HydratedDocument<FotoDocument>;
export const FotoSchema = SchemaFactory.createForClass(FotoDocument);

