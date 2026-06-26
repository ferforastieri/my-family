import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';
import type {
  SiteConfigValue,
  SiteSectionKey,
} from '../infrastructure/persistence/site-config.schema';

const sectionKeys: SiteSectionKey[] = [
  'events',
  'gallery',
  'songs',
  'letters',
  'journey',
];

class SiteBrandDto {
  @IsOptional()
  @IsString()
  @MaxLength(500)
  logoPath?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  coverPath?: string;

  @IsString()
  @Matches(/^#[0-9a-fA-F]{6}$/)
  primaryColor: string;

  @IsString()
  @Matches(/^#[0-9a-fA-F]{6}$/)
  secondaryColor: string;

  @IsIn(['romantic', 'classic', 'modern'])
  fontPreset: 'romantic' | 'classic' | 'modern';
}

class SiteSeoDto {
  @IsString()
  @MinLength(3)
  @MaxLength(70)
  title: string;

  @IsString()
  @MinLength(10)
  @MaxLength(180)
  description: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  socialImagePath?: string;
}

class SiteSectionDto {
  @IsIn(sectionKeys)
  key: SiteSectionKey;

  @IsBoolean()
  visible: boolean;

  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(20)
  order: number;

  @IsArray()
  @ArrayMaxSize(100)
  @IsString({ each: true })
  selectedIds: string[];
}

export class UpdateSiteConfigDto implements SiteConfigValue {
  @ValidateNested()
  @Type(() => SiteBrandDto)
  brand: SiteBrandDto;

  @ValidateNested()
  @Type(() => SiteSeoDto)
  seo: SiteSeoDto;

  @IsArray()
  @ArrayMaxSize(5)
  @ValidateNested({ each: true })
  @Type(() => SiteSectionDto)
  sections: SiteSectionDto[];
}
