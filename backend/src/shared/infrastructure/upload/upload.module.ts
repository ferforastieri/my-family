import { Global, Module } from '@nestjs/common';
import { EnvironmentModule } from '@shared/infrastructure/environment/environment.module';
import { UploadService } from './upload.service';

@Global()
@Module({
  imports: [EnvironmentModule],
  providers: [UploadService],
  exports: [UploadService],
})
export class UploadModule {}
