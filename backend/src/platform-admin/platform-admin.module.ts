import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AuditModule } from '../audit/audit.module';
import { PlatformAdminController } from './platform-admin.controller';
import { PlatformAdminGuard } from './platform-admin.guard';
import { PlatformAdminService } from './platform-admin.service';
import { PlatformAdminGateway } from './platform-admin.gateway';
import { AuthModule } from '@auth/auth.module';
import { BillingModule } from '../billing/billing.module';
import {
  SubscriptionDocument,
  SubscriptionSchema,
} from '../billing/infrastructure/persistence/subscription.schema';
import {
  TenantDocument,
  TenantSchema,
} from '../tenancy/infrastructure/persistence/tenant.schema';
import {
  UserDocument,
  UserSchema,
} from '../auth/infrastructure/persistence/user.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: UserDocument.name, schema: UserSchema },
      { name: TenantDocument.name, schema: TenantSchema },
      { name: SubscriptionDocument.name, schema: SubscriptionSchema },
    ]),
    AuditModule,
    AuthModule,
    BillingModule,
  ],
  controllers: [PlatformAdminController],
  providers: [PlatformAdminService, PlatformAdminGuard, PlatformAdminGateway],
})
export class PlatformAdminModule {}
