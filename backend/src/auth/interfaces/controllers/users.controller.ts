import {
  Controller,
  Get,
  Patch,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
  NotFoundException,
} from '@nestjs/common';
import { UserService } from '@auth/application/services/user.service';
import { RolesGuard } from '@auth/guards/roles.guard';
import { Roles } from '@auth/decorators/roles.decorator';
import { UpdateUserDto } from '../dto/user.dto';
import { PaginationMessageDto } from '@shared/interfaces/websocket/websocket.dto';

@Controller('users')
@UseGuards(RolesGuard)
@Roles('owner', 'admin')
export class UsersController {
  constructor(private user: UserService) {}

  @Get()
  list(@Query() query: PaginationMessageDto) {
    return this.user.list(query);
  }

  @Get(':id')
  async one(@Param('id') id: string) {
    const user = await this.user.findOne(id);
    if (!user) throw new NotFoundException('Usuário não encontrado');
    return user;
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() dto: UpdateUserDto) {
    const user = await this.user.update(id, dto);
    if (!user) throw new NotFoundException('Usuário não encontrado');
    return { message: 'Usuário atualizado.', ...user };
  }

  @Delete(':id')
  async delete(@Param('id') id: string) {
    const ok = await this.user.delete(id);
    if (!ok) throw new NotFoundException('Usuário não encontrado');
    return { ok, message: 'Usuário removido.' };
  }
}
