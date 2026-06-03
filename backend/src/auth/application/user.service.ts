import { Injectable } from '@nestjs/common';
import { UserRepository } from '../infrastructure/repositories/user.repository';
import type { UserRole } from '@shared/domain/entities';
import type { PaginatedResult, PaginationQuery } from '@shared/infrastructure/database/mongo.utils';

export type UserDto = {
  id: string;
  email: string;
  name: string | null;
  role: UserRole;
  avatarPath: string | null;
  createdAt: Date;
};

@Injectable()
export class UserService {
  constructor(private users: UserRepository) {}

  async list(query?: PaginationQuery): Promise<PaginatedResult<UserDto>> {
    const page = await this.users.list(query);
    return {
      ...page,
      items: page.items.map(({ id, email, name, role, avatarPath, createdAt }) => ({
      id,
      email,
      name: name ?? null,
      role,
      avatarPath: avatarPath ?? null,
      createdAt,
      })),
    };
  }

  async findOne(id: string): Promise<UserDto | null> {
    const row = await this.users.findById(id);
    return row
      ? {
          id: row.id,
          email: row.email,
          name: row.name ?? null,
          role: row.role,
          avatarPath: row.avatarPath ?? null,
          createdAt: row.createdAt,
        }
      : null;
  }

  async update(id: string, data: { name?: string; role?: UserRole; avatarPath?: string }): Promise<UserDto | null> {
    await this.users.update(id, data);
    return this.findOne(id);
  }

  async delete(id: string): Promise<boolean> {
    return this.users.delete(id);
  }
}
