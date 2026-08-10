import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Access } from '@auth/decorators/access.decorator';
import { Roles } from '@auth/decorators/roles.decorator';
import type { UserEntity } from '@auth/domain/entities/user.entity';
import { AccessGuard } from '@auth/guards/access.guard';
import { JwtAuthGuard } from '@auth/guards/jwt-auth.guard';
import { RolesGuard } from '@auth/guards/roles.guard';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import { GamesService } from '../../application/services/games.service';
import {
  GameCompletionWriteDto,
  GameWordWriteDto,
  MiniGameConfigWriteDto,
  QuizQuestionWriteDto,
} from '../dto/game.dto';

@Controller('games')
@UseGuards(JwtAuthGuard, AccessGuard)
@Access('jogos')
export class GamesController {
  constructor(private readonly games: GamesService) {}

  @Get('quiz')
  quiz(@Query() query: PaginationQuery) {
    return this.games.quizPublic(query);
  }

  @Get('quiz/admin')
  @UseGuards(RolesGuard)
  @Roles('husband', 'wife')
  quizAdmin(@Query() query: PaginationQuery) {
    return this.games.quizAdmin(query);
  }

  @Post('quiz')
  @UseGuards(RolesGuard)
  @Roles('husband', 'wife')
  async createQuestion(@Body() data: QuizQuestionWriteDto) {
    const row = await this.games.createQuestion(data);
    return { message: 'Pergunta salva.', ...row };
  }

  @Put('quiz/:id')
  @UseGuards(RolesGuard)
  @Roles('husband', 'wife')
  async updateQuestion(
    @Param('id') id: string,
    @Body() data: Partial<QuizQuestionWriteDto>,
  ) {
    const row = await this.games.updateQuestion(id, data);
    return row ? { message: 'Pergunta atualizada.', ...row } : row;
  }

  @Delete('quiz/:id')
  @UseGuards(RolesGuard)
  @Roles('husband', 'wife')
  async deleteQuestion(@Param('id') id: string) {
    return {
      ok: await this.games.deleteQuestion(id),
      message: 'Pergunta removida.',
    };
  }

  @Get('words')
  words(@Query() query: PaginationQuery) {
    return this.games.wordsPublic(query);
  }

  @Get('words/admin')
  @UseGuards(RolesGuard)
  @Roles('husband', 'wife')
  wordsAdmin(@Query() query: PaginationQuery) {
    return this.games.wordsAdmin(query);
  }

  @Post('words')
  @UseGuards(RolesGuard)
  @Roles('husband', 'wife')
  async createWord(@Body() data: GameWordWriteDto) {
    const row = await this.games.createWord(data);
    return { message: 'Palavra salva.', ...row };
  }

  @Put('words/:id')
  @UseGuards(RolesGuard)
  @Roles('husband', 'wife')
  async updateWord(
    @Param('id') id: string,
    @Body() data: Partial<GameWordWriteDto>,
  ) {
    const row = await this.games.updateWord(id, data);
    return row ? { message: 'Palavra atualizada.', ...row } : row;
  }

  @Delete('words/:id')
  @UseGuards(RolesGuard)
  @Roles('husband', 'wife')
  async deleteWord(@Param('id') id: string) {
    return {
      ok: await this.games.deleteWord(id),
      message: 'Palavra removida.',
    };
  }

  @Get('mini')
  mini(@Query() query: PaginationQuery) {
    return this.games.miniGamesPublic(query);
  }

  @Get('mini/admin')
  @UseGuards(RolesGuard)
  @Roles('husband', 'wife')
  miniAdmin(@Query() query: PaginationQuery) {
    return this.games.miniGamesAdmin(query);
  }

  @Post('mini')
  @UseGuards(RolesGuard)
  @Roles('husband', 'wife')
  async createMini(@Body() data: MiniGameConfigWriteDto) {
    const row = await this.games.createMiniGame(data);
    return { message: 'Mini jogo salvo.', ...row };
  }

  @Put('mini/:id')
  @UseGuards(RolesGuard)
  @Roles('husband', 'wife')
  async updateMini(
    @Param('id') id: string,
    @Body() data: Partial<MiniGameConfigWriteDto>,
  ) {
    const row = await this.games.updateMiniGame(id, data);
    return row ? { message: 'Mini jogo atualizado.', ...row } : row;
  }

  @Delete('mini/:id')
  @UseGuards(RolesGuard)
  @Roles('husband', 'wife')
  async deleteMini(@Param('id') id: string) {
    return {
      ok: await this.games.deleteMiniGame(id),
      message: 'Mini jogo removido.',
    };
  }

  @Post('complete')
  async complete(
    @Req() request: { user: UserEntity },
    @Body() data: GameCompletionWriteDto,
  ) {
    const row = await this.games.complete(data, request.user);
    return { message: 'Jogo concluído.', ...row };
  }

  @Get('stats')
  @UseGuards(RolesGuard)
  @Roles('husband', 'wife')
  stats(@Query() query: PaginationQuery) {
    return this.games.stats(query);
  }
}
