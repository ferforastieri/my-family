import { IsDateString, IsIn, IsOptional, IsString } from 'class-validator';
import type { FotoEntity } from '@fotos/domain/entities/foto.entity';

export class FotoWriteDto {
  @IsString()
  url: string;

  @IsIn(['imagem', 'video'])
  tipo: FotoEntity['tipo'];

  @IsOptional()
  @IsString()
  texto?: string;

  @IsOptional()
  @IsString()
  album?: string;

  @IsOptional()
  @IsDateString()
  data?: string;
}

export class FotoResponseDto {
  id: string;
  url: string;
  texto: string | null;
  album: string | null;
  tipo: FotoEntity['tipo'];
  data: Date | null;
  createdAt: Date;
  updatedAt: Date;
}
