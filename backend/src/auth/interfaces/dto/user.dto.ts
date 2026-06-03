import { IsIn, IsOptional, IsString } from 'class-validator';
import { userRoles, type UserRole } from '@shared/domain/entities';

export class UpdateUserDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsIn(userRoles)
  role?: UserRole;

  @IsOptional()
  @IsString()
  avatarPath?: string;
}

export class UserResponseDto {
  id: string;
  email: string;
  name: string | null;
  role: UserRole;
  avatarPath: string | null;
  createdAt: Date;
}
