import { Injectable } from '@nestjs/common';
import { UserRepository } from '../infrastructure/repositories/user.repository';
import type {
  PaginatedResult,
  PaginationQuery,
} from '@shared/infrastructure/database/mongo.utils';
import { userMapper } from './user.mapper';
import { userUpdateFactory } from './user.factory';
import { UpdateUserDto, UserResponseDto } from '../interfaces/dto/user.dto';

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
    await this.users.update(id, userUpdateFactory.create(data));
    return this.findOne(id);
  }

  async delete(id: string): Promise<boolean> {
    return this.users.delete(id);
  }
}
