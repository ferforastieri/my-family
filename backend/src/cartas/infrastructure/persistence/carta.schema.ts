import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';
import { applyTenantScope } from '@tenancy/infrastructure/tenant-scope.plugin';

@Schema({ timestamps: true, collection: 'cartas' })
export class CartaDocument {
  tenantId: string;

  @Prop({
    type: String,
    required: true,
    enum: ['letter', 'journey'],
    index: true,
  })
  tipo: 'letter' | 'journey';

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
applyTenantScope(CartaSchema);
