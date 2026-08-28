import { Module } from '@nestjs/common';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { AuthModule } from '@auth/auth.module';
import { TenancyModule } from '@tenancy/tenancy.module';
import { DemoController } from './demo.controller';
import { DemoService } from './demo.service';
import { DemoCleanupProcessor } from './demo-cleanup.processor';
import { UserRepository } from '@auth/infrastructure/repositories/user.repository';
import { TurnstileService } from '@shared/infrastructure/security/turnstile.service';
@Module({
  imports: [MongoModelsModule, AuthModule, TenancyModule],
  controllers: [DemoController],
  providers: [
    DemoService,
    DemoCleanupProcessor,
    UserRepository,
    TurnstileService,
  ],
})
export class DemoModule {}
