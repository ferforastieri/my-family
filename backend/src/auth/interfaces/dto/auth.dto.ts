import {
  IsEmail,
  IsString,
  MinLength,
  IsIn,
  IsOptional,
} from 'class-validator';
import type { TenantLocale } from '@tenancy/domain/tenant.entity';

export class RegisterDto {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8)
  password: string;

  @IsString()
  @IsOptional()
  name?: string;

  @IsString()
  @MinLength(2)
  familyName: string;

  @IsString()
  @MinLength(3)
  @IsOptional()
  slug?: string;

  @IsIn(['pt-BR', 'en', 'es'])
  @IsOptional()
  locale?: TenantLocale;
}

export class LoginDto {
  @IsEmail()
  email: string;

  @IsString()
  password: string;

  @IsString()
  @IsOptional()
  tenantSlug?: string;
}

export class RefreshTokenDto {
  @IsString()
  @IsOptional()
  refreshToken?: string;

  @IsString()
  @IsOptional()
  refresh_token?: string;
}
