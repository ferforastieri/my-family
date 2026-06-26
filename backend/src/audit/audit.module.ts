import { Global, MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AuditService } from './application/audit.service';
import { AuditMiddleware } from './infrastructure/audit.middleware';
import {
  AuditLogDocument,
  AuditLogSchema,
} from './infrastructure/persistence/audit-log.schema';
import { AuditController } from './interfaces/audit.controller';

@Global()
@Module({
  imports: [
    MongooseModule.forFeature([
      { name: AuditLogDocument.name, schema: AuditLogSchema },
    ]),
  ],
  controllers: [AuditController],
  providers: [AuditService, AuditMiddleware],
  exports: [AuditService],
})
export class AuditModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(AuditMiddleware).forRoutes('*');
  }
}
