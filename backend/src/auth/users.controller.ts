import { Controller, Get, Patch, Delete, Param, Body, UseGuards, ParseIntPipe, NotFoundException } from '@nestjs/common';
import { UserService } from '@auth/user.service';
import { JwtAuthGuard } from '@auth/guards/jwt-auth.guard';
import { RolesGuard } from '@auth/guards/roles.guard';
import { Roles } from '@auth/decorators/roles.decorator';
import { userRoles, type UserRole } from '@shared/infrastructure/database/schema';
import { IsOptional, IsString, IsIn } from 'class-validator';

class UpdateUserDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsIn(userRoles)
  role?: UserRole;
}

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
  async one(@Param('id', ParseIntPipe) id: number) {
    const user = await this.user.findOne(id);
    if (!user) throw new NotFoundException('Usuário não encontrado');
    return user;
  }

  @Patch(':id')
  async update(@Param('id', ParseIntPipe) id: number, @Body() dto: UpdateUserDto) {
    const user = await this.user.update(id, { name: dto.name, role: dto.role });
    if (!user) throw new NotFoundException('Usuário não encontrado');
    return user;
  }

  @Delete(':id')
  async delete(@Param('id', ParseIntPipe) id: number) {
    const ok = await this.user.delete(id);
    if (!ok) throw new NotFoundException('Usuário não encontrado');
  }
}
