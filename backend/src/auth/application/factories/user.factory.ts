import type { Factory } from '@shared/application/mapper';
import { UpdateUserDto } from '../../interfaces/dto/user.dto';

export class UserUpdateFactory implements Factory<
  UpdateUserDto,
  UpdateUserDto & { passwordHash?: string }
> {
  create(input: UpdateUserDto): UpdateUserDto & { passwordHash?: string } {
    return {
      name: input.name?.trim(),
      avatarPath: input.avatarPath,
    };
  }
}

export const userUpdateFactory = new UserUpdateFactory();
