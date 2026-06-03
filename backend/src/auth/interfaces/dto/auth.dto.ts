import {
  IsEmail,
  IsString,
  MinLength,
  IsOptional,
  IsIn,
} from 'class-validator';
import { userRoles } from '@auth/domain/entities/user.entity';

export class RegisterDto {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(6)
  password: string;

  @IsString()
  @IsOptional()
  name?: string;

  @IsString()
  @IsOptional()
  @IsIn(userRoles)
  role?: (typeof userRoles)[number];
}

export class LoginDto {
  @IsEmail()
  email: string;

  @IsString()
  password: string;
}
