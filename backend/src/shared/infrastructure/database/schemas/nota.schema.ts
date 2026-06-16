import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

@Schema({ timestamps: true, collection: 'notas' })
export class NotaDocument {
  @Prop({ required: true })
  titulo: string;

  @Prop({ required: true })
  conteudo: string;

  @Prop({ default: Date.now })
  data: Date;

  createdAt: Date;
  updatedAt: Date;
}

export type NotaMongoDocument = HydratedDocument<NotaDocument>;
export const NotaSchema = SchemaFactory.createForClass(NotaDocument);
