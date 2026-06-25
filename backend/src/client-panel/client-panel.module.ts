import { Module } from '@nestjs/common';
import { AuthModule } from '@auth/auth.module';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { ClientPanelGateway } from './client-panel.gateway';
import { ClientPanelService } from './client-panel.service';

@Module({
  imports: [MongoModelsModule, AuthModule],
  providers: [ClientPanelService, ClientPanelGateway],
})
export class ClientPanelModule {}
