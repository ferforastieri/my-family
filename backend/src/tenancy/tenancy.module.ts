import { Global, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { TenantContext } from './application/tenant-context';
import { TenantService } from './application/tenant.service';
import { TenantRepository } from './infrastructure/tenant.repository';
import { TenantController } from './interfaces/tenant.controller';
import {
  MembershipDocument,
  MembershipSchema,
} from './infrastructure/persistence/membership.schema';
import {
  TenantDocument,
  TenantSchema,
} from './infrastructure/persistence/tenant.schema';

@Global()
@Module({
  imports: [
    MongooseModule.forFeature([
      { name: TenantDocument.name, schema: TenantSchema },
      { name: MembershipDocument.name, schema: MembershipSchema },
    ]),
  ],
  controllers: [TenantController],
  providers: [TenantContext, TenantService, TenantRepository],
  exports: [TenantContext, TenantService, TenantRepository],
})
export class TenancyModule {}
