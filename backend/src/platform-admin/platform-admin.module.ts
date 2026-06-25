import { Module } from '@nestjs/common';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { AuditModule } from '../audit/audit.module';
import { PlatformAdminController } from './platform-admin.controller';
import { PlatformAdminGuard } from './platform-admin.guard';
import { PlatformAdminService } from './platform-admin.service';

@Module({
  imports: [MongoModelsModule, AuditModule],
  controllers: [PlatformAdminController],
  providers: [PlatformAdminService, PlatformAdminGuard],
})
export class PlatformAdminModule {}
