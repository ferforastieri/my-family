import { Global, MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { AuditService } from './application/audit.service';
import { AuditMiddleware } from './infrastructure/audit.middleware';
import { AuditController } from './interfaces/audit.controller';

@Global()
@Module({
  imports: [MongoModelsModule],
  controllers: [AuditController],
  providers: [AuditService, AuditMiddleware],
  exports: [AuditService],
})
export class AuditModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(AuditMiddleware).forRoutes('*');
  }
}
