import { Body, Controller, Get, Patch, Post } from '@nestjs/common';
import {
  IsBoolean,
  IsIn,
  IsObject,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';
import { TenantService } from '../application/tenant.service';
import type { TenantLocale } from '../domain/tenant.entity';

class UpdateTenantDto {
  @IsString()
  @MinLength(2)
  @IsOptional()
  name?: string;

  @IsString()
  @MinLength(3)
  @IsOptional()
  slug?: string;

  @IsIn(['pt-BR', 'en', 'es'])
  @IsOptional()
  defaultLocale?: TenantLocale;

  @IsObject()
  @IsOptional()
  theme?: Record<string, unknown>;
}

class PublishTenantDto {
  @IsBoolean()
  isPublished: boolean;
}

@Controller('tenants')
export class TenantController {
  constructor(private tenants: TenantService) {}

  @Get('current')
  current() {
    return this.tenants.current();
  }

  @Patch('current')
  update(@Body() body: UpdateTenantDto) {
    return this.tenants.updateCurrent(body);
  }

  @Post('current/publication')
  publish(@Body() body: PublishTenantDto) {
    return this.tenants.setPublished(body.isPublished);
  }
}
