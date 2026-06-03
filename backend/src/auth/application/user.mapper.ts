import type { Mapper } from '@shared/application/mapper';
import type { UserEntity } from '@shared/domain/entities';
import { UserResponseDto } from '../interfaces/dto/user.dto';

export class UserMapper implements Mapper<UserEntity, UserResponseDto> {
  toDto(source: UserEntity): UserResponseDto {
    return {
      id: source.id,
      email: source.email,
      name: source.name ?? null,
      role: source.role,
      avatarPath: source.avatarPath ?? null,
      createdAt: source.createdAt,
    };
  }
}

export const userMapper = new UserMapper();
