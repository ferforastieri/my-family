import type { Factory } from '@shared/application/mapper';
import { UpdateUserDto } from '../interfaces/dto/user.dto';

export class UserUpdateFactory implements Factory<
  UpdateUserDto,
  UpdateUserDto
> {
  create(input: UpdateUserDto): UpdateUserDto {
    return {
      name: input.name?.trim(),
      role: input.role,
      avatarPath: input.avatarPath,
    };
  }
}

export const userUpdateFactory = new UserUpdateFactory();
