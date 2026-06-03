import {
  Controller,
  Get,
  Patch,
  Delete,
  Param,
  Body,
  UseGuards,
  NotFoundException,
} from '@nestjs/common';
import { UserService } from '@auth/application/user.service';
import { JwtAuthGuard } from '@auth/guards/jwt-auth.guard';
import { RolesGuard } from '@auth/guards/roles.guard';
import { Roles } from '@auth/decorators/roles.decorator';
import { UpdateUserDto } from '../dto/user.dto';

@Controller('users')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
export class UsersController {
  constructor(private user: UserService) {}

  @Get()
  list() {
    return this.user.list();
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
    return user;
  }

  @Delete(':id')
  async delete(@Param('id') id: string) {
    const ok = await this.user.delete(id);
    if (!ok) throw new NotFoundException('Usuário não encontrado');
  }
}
