import {
  IsArray,
  IsIn,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';
import {
  userAccessKeys,
  userRoles,
  type UserAccessKey,
  type UserRole,
} from '@auth/domain/entities/user.entity';

export class UpdateUserDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsIn(userRoles)
  role?: UserRole;

  @IsOptional()
  @IsArray()
  @IsIn(userAccessKeys, { each: true })
  access?: UserAccessKey[];

  @IsOptional()
  @IsString()
  avatarPath?: string;

  @IsOptional()
  @IsString()
  @MinLength(8)
  password?: string;
}

export class UserResponseDto {
  id: string;
  email: string;
  name: string | null;
  role: UserRole;
  access: UserAccessKey[];
  avatarPath: string | null;
  tenantId: string;
  tenantSlug: string | null;
  createdAt: Date;
}
