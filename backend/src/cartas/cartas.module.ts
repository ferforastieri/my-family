import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { CartasController } from './interfaces/controllers/cartas.controller';
import { CartasService } from './application/services/cartas.service';
import { CartasRepository } from './infrastructure/repositories/cartas.repository';
import { AuthModule } from '@auth/auth.module';
import { CartasGateway } from './interfaces/gateways/cartas.gateway';
import { NotificationsModule } from '../notifications/notifications.module';
import { CARTAS_REPOSITORY } from './application/ports/cartas.repository.port';
import { CARTA_NOTIFIER } from './application/ports/carta-notifier.port';
import { CartaNotifierAdapter } from './infrastructure/notifications/carta-notifier.adapter';
import {
  CartaDocument,
  CartaSchema,
} from './infrastructure/persistence/carta.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: CartaDocument.name, schema: CartaSchema },
    ]),
    AuthModule,
    NotificationsModule,
  ],
  controllers: [CartasController],
  providers: [
    CartasService,
    CartasGateway,
    CartaNotifierAdapter,
    { provide: CARTAS_REPOSITORY, useClass: CartasRepository },
    { provide: CARTA_NOTIFIER, useExisting: CartaNotifierAdapter },
  ],
  exports: [CartasService],
})
export class CartasModule {}
