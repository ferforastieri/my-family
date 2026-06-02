import { Module } from '@nestjs/common';
import { AuthModule } from '@auth/auth.module';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { GamesService } from './application/games.service';
import { GamesRepository } from './infrastructure/repositories/games.repository';
import { GamesGateway } from './interfaces/gateways/games.gateway';

@Module({
  imports: [MongoModelsModule, AuthModule],
  providers: [GamesService, GamesRepository, GamesGateway],
  exports: [GamesService],
})
export class GamesModule {}
