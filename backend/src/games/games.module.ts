import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AuthModule } from '@auth/auth.module';
import { GamesService } from './application/services/games.service';
import { GamesRepository } from './infrastructure/repositories/games.repository';
import { GamesController } from './interfaces/controllers/games.controller';
import {
  GameCompletionDocument,
  GameCompletionSchema,
} from './infrastructure/persistence/game-completion.schema';
import {
  GameWordDocument,
  GameWordSchema,
} from './infrastructure/persistence/game-word.schema';
import {
  MiniGameConfigDocument,
  MiniGameConfigSchema,
} from './infrastructure/persistence/mini-game-config.schema';
import {
  QuizQuestionDocument,
  QuizQuestionSchema,
} from './infrastructure/persistence/quiz-question.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: QuizQuestionDocument.name, schema: QuizQuestionSchema },
      { name: GameCompletionDocument.name, schema: GameCompletionSchema },
      { name: GameWordDocument.name, schema: GameWordSchema },
      { name: MiniGameConfigDocument.name, schema: MiniGameConfigSchema },
    ]),
    AuthModule,
  ],
  controllers: [GamesController],
  providers: [GamesService, GamesRepository],
  exports: [GamesService],
})
export class GamesModule {}
