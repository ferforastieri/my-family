import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

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

export type CartaMongoDocument = HydratedDocument<CartaDocument>;
export const CartaSchema = SchemaFactory.createForClass(CartaDocument);
