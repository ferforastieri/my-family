import { Global, Module } from '@nestjs/common';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { TenantContext } from './application/tenant-context';
import { TenantService } from './application/tenant.service';
import { TenantRepository } from './infrastructure/tenant.repository';
import { TenantController } from './interfaces/tenant.controller';

@Global()
@Module({
  imports: [MongoModelsModule],
  controllers: [TenantController],
  providers: [TenantContext, TenantService, TenantRepository],
  exports: [TenantContext, TenantService, TenantRepository],
})
export class TenancyModule {}

