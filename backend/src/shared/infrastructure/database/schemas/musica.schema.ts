import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

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

export type MusicaMongoDocument = HydratedDocument<MusicaDocument>;
export const MusicaSchema = SchemaFactory.createForClass(MusicaDocument);

