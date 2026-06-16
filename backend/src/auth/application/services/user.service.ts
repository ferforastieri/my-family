import { BadRequestException, Injectable } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { UserRepository } from '../../infrastructure/repositories/user.repository';
import type {
  PaginatedResult,
  PaginationQuery,
} from '@shared/infrastructure/database/mongo.utils';
import { userMapper } from '../mappers/user.mapper';
import { userUpdateFactory } from '../factories/user.factory';
import { UpdateUserDto, UserResponseDto } from '../../interfaces/dto/user.dto';

@Injectable()
export class UserService {
  constructor(private users: UserRepository) {}

  async list(
    query?: PaginationQuery,
  ): Promise<PaginatedResult<UserResponseDto>> {
    const page = await this.users.list(query);
    return {
      ...page,
      items: page.items.map((user) => userMapper.toDto(user)),
    };
  }

  async findOne(id: string): Promise<UserResponseDto | null> {
    const row = await this.users.findById(id);
    return row ? userMapper.toDto(row) : null;
  }

  async update(
    id: string,
    data: UpdateUserDto,
  ): Promise<UserResponseDto | null> {
    const updateData = userUpdateFactory.create(data);
    const password = data.password?.trim();
    if (password) {
      if (password.length < 8) {
        throw new BadRequestException(
          'A senha deve ter pelo menos 8 caracteres',
        );
      }
      updateData.passwordHash = await bcrypt.hash(password, 12);
    }
    await this.users.update(id, updateData);
    return this.findOne(id);
  }

  async delete(id: string): Promise<boolean> {
    return this.users.delete(id);
  }
}
