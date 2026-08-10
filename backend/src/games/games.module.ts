import { Module } from '@nestjs/common';
import { AuthModule } from '@auth/auth.module';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { GamesService } from './application/services/games.service';
import { GamesRepository } from './infrastructure/repositories/games.repository';
import { GamesController } from './interfaces/controllers/games.controller';

@Module({
  imports: [MongoModelsModule, AuthModule],
  controllers: [GamesController],
  providers: [GamesService, GamesRepository],
  exports: [GamesService],
})
export class GamesModule {}
