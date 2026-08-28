import { Module } from '@nestjs/common';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { UserRepository } from '@auth/infrastructure/repositories/user.repository';
import { TenancyRepository } from './infrastructure/tenancy.repository';
import { TenancyService } from './application/tenancy.service';
import {
  TenantController,
  InvitationsController,
} from './interfaces/tenant.controller';
import { TenantAdminGuard } from './interfaces/tenant-admin.guard';
import { PlatformController } from './interfaces/platform.controller';
import { PlatformAdminGuard } from './interfaces/platform-admin.guard';
import { DemoRestrictedGuard } from './interfaces/demo-restricted.guard';
import { PhoneMessagingService } from '@auth/application/services/phone-messaging.service';

@Module({
  imports: [MongoModelsModule],
  controllers: [TenantController, InvitationsController, PlatformController],
  providers: [
    TenancyRepository,
    TenancyService,
    UserRepository,
    TenantAdminGuard,
    PlatformAdminGuard,
    DemoRestrictedGuard,
    PhoneMessagingService,
  ],
  exports: [
    TenancyRepository,
    TenancyService,
    TenantAdminGuard,
    PlatformAdminGuard,
    DemoRestrictedGuard,
  ],
})
export class TenancyModule {}
