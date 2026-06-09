import { SetMetadata } from '@nestjs/common';
import type { UserAccessKey } from '@auth/domain/entities/user.entity';

export const ACCESS_KEY = 'access';

export const Access = (accessKey: UserAccessKey) =>
  SetMetadata(ACCESS_KEY, accessKey);
