import { IsDateString, IsOptional, IsString } from 'class-validator';
import { PartialType } from '@nestjs/mapped-types';
import { Type } from 'class-transformer';
import { ValidateNested } from 'class-validator';

export class NotaWriteDto {
  @IsString()
  titulo: string;

  @IsString()
  conteudo: string;

  @IsOptional()
  @IsDateString()
  data?: string;
}

export class NotaUpdateDto extends PartialType(NotaWriteDto) {}

export class NotaUpdateMessageDto {
  @IsString()
  id: string;

  @ValidateNested()
  @Type(() => NotaUpdateDto)
  data: NotaUpdateDto;
}

export class NotaResponseDto {
  id: string;
  titulo: string;
  conteudo: string;
  data: Date;
  createdAt: Date;
  updatedAt: Date;
}
