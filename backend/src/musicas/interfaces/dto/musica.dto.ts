import { IsDateString, IsOptional, IsString } from 'class-validator';
import { PartialType } from '@nestjs/mapped-types';
import { Type } from 'class-transformer';
import { ValidateNested } from 'class-validator';

export class MusicaWriteDto {
  @IsString()
  titulo: string;

  @IsString()
  artista: string;

  @IsString()
  linkSpotify: string;

  @IsString()
  momento: string;

  @IsOptional()
  @IsString()
  descricao?: string;

  @IsOptional()
  @IsDateString()
  data?: string;
}

export class MusicaUpdateDto extends PartialType(MusicaWriteDto) {}

export class MusicaUpdateMessageDto {
  @IsString()
  id: string;

  @ValidateNested()
  @Type(() => MusicaUpdateDto)
  data: MusicaUpdateDto;
}

export class MusicaResponseDto {
  id: string;
  titulo: string;
  artista: string;
  linkSpotify: string;
  descricao: string | null;
  momento: string;
  data: Date;
  createdAt: Date;
  updatedAt: Date;
}
