import { Module } from '@nestjs/common';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { AuditModule } from '../audit/audit.module';
import { PlatformAdminController } from './platform-admin.controller';
import { PlatformAdminGuard } from './platform-admin.guard';
import { PlatformAdminService } from './platform-admin.service';
import { PlatformAdminGateway } from './platform-admin.gateway';
import { AuthModule } from '@auth/auth.module';

@Module({
  imports: [MongoModelsModule, AuditModule, AuthModule],
  controllers: [PlatformAdminController],
  providers: [
    PlatformAdminService,
    PlatformAdminGuard,
    PlatformAdminGateway,
  ],
})
export class PlatformAdminModule {}
