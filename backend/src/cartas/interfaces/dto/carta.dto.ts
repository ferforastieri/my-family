import { Type } from 'class-transformer';
import {
  IsDateString,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';

export class CartaWriteDto {
  @IsString()
  titulo: string;

  @IsString()
  conteudo: string;

  @IsOptional()
  @IsDateString()
  data?: string;
}

export class CartaUpdateDto {
  @IsOptional()
  @IsString()
  titulo?: string;

  @IsOptional()
  @IsString()
  conteudo?: string;

  @IsOptional()
  @IsDateString()
  data?: string;
}

export class CartaUpdateMessageDto {
  @IsString()
  id: string;

  @ValidateNested()
  @Type(() => CartaUpdateDto)
  data: CartaUpdateDto;
}

export class CartaDeleteMessageDto {
  @IsString()
  id: string;
}

export class CartaResponseDto {
  id: string;
  tipo: 'letter' | 'journey';
  titulo: string;
  conteudo: string;
  data: Date;
  createdAt: Date;
  updatedAt: Date;
}
