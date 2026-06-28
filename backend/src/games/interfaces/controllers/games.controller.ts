import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Access } from '@auth/decorators/access.decorator';
import { AccessGuard } from '@auth/guards/access.guard';
import { Roles } from '@auth/decorators/roles.decorator';
import { RolesGuard } from '@auth/guards/roles.guard';
import type { UserEntity } from '@auth/domain/entities/user.entity';
import { PaginationMessageDto } from '@shared/interfaces/websocket/websocket.dto';
import { GamesService } from '../../application/services/games.service';
import {
  GameCompletionWriteDto,
  GameWordUpdateDto,
  GameWordWriteDto,
  MiniGameConfigUpdateDto,
  MiniGameConfigWriteDto,
  QuizQuestionUpdateDto,
  QuizQuestionWriteDto,
} from '../dto/game.dto';

@Controller('games')
export class GamesController {
  constructor(private readonly games: GamesService) {}

  @Get('quiz')
  @UseGuards(AccessGuard)
  @Access('jogos')
  quiz(@Query() query: PaginationMessageDto) {
    return this.games.quizPublic(query);
  }

  @Get('quiz/admin')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin')
  quizAdmin(@Query() query: PaginationMessageDto) {
    return this.games.quizAdmin(query);
  }

  @Post('quiz')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin')
  async createQuestion(@Body() body: QuizQuestionWriteDto) {
    const row = await this.games.createQuestion(body);
    return { message: 'Pergunta salva.', ...row };
  }

  @Patch('quiz/:id')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin')
  async updateQuestion(
    @Param('id') id: string,
    @Body() body: QuizQuestionUpdateDto,
  ) {
    const row = await this.games.updateQuestion(id, body);
    return row ? { message: 'Pergunta atualizada.', ...row } : row;
  }

  @Delete('quiz/:id')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin')
  async deleteQuestion(@Param('id') id: string) {
    return { ok: await this.games.deleteQuestion(id), message: 'Pergunta removida.' };
  }

  @Get('words')
  @UseGuards(AccessGuard)
  @Access('jogos')
  words(@Query() query: PaginationMessageDto) {
    return this.games.wordsPublic(query);
  }

  @Get('words/admin')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin')
  wordsAdmin(@Query() query: PaginationMessageDto) {
    return this.games.wordsAdmin(query);
  }

  @Post('words')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin')
  async createWord(@Body() body: GameWordWriteDto) {
    const row = await this.games.createWord(body);
    return { message: 'Palavra salva.', ...row };
  }

  @Patch('words/:id')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin')
  async updateWord(@Param('id') id: string, @Body() body: GameWordUpdateDto) {
    const row = await this.games.updateWord(id, body);
    return row ? { message: 'Palavra atualizada.', ...row } : row;
  }

  @Delete('words/:id')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin')
  async deleteWord(@Param('id') id: string) {
    return { ok: await this.games.deleteWord(id), message: 'Palavra removida.' };
  }

  @Get('mini')
  @UseGuards(AccessGuard)
  @Access('jogos')
  mini(@Query() query: PaginationMessageDto) {
    return this.games.miniGamesPublic(query);
  }

  @Get('mini/admin')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin')
  miniAdmin(@Query() query: PaginationMessageDto) {
    return this.games.miniGamesAdmin(query);
  }

  @Post('mini')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin')
  async createMini(@Body() body: MiniGameConfigWriteDto) {
    const row = await this.games.createMiniGame(body);
    return { message: 'Mini jogo salvo.', ...row };
  }

  @Patch('mini/:id')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin')
  async updateMini(
    @Param('id') id: string,
    @Body() body: MiniGameConfigUpdateDto,
  ) {
    const row = await this.games.updateMiniGame(id, body);
    return row ? { message: 'Mini jogo atualizado.', ...row } : row;
  }

  @Delete('mini/:id')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin')
  async deleteMini(@Param('id') id: string) {
    return { ok: await this.games.deleteMiniGame(id), message: 'Mini jogo removido.' };
  }

  @Post('complete')
  @UseGuards(AccessGuard)
  @Access('jogos')
  async complete(
    @Req() request: { user: UserEntity },
    @Body() body: GameCompletionWriteDto,
  ) {
    const row = await this.games.complete(body, request.user);
    return { message: 'Jogo concluído.', ...row };
  }

  @Get('stats')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin')
  stats(@Query() query: PaginationMessageDto) {
    return this.games.stats(query);
  }
}
