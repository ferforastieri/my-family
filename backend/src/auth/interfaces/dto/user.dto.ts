import { IsArray, IsIn, IsOptional } from 'class-validator';
import {
  userAccessKeys,
  userRoles,
  type UserAccessKey,
  type UserRole,
} from '@auth/domain/entities/user.entity';

export class UpdateUserDto {
  @IsOptional()
  @IsIn(['admin', 'member'])
  membershipRole?: 'admin' | 'member';

  @IsOptional()
  @IsIn(userRoles)
  role?: UserRole;

  @IsOptional()
  @IsArray()
  @IsIn(userAccessKeys, { each: true })
  access?: UserAccessKey[];
}
