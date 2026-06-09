import { IsDateString, IsOptional, IsString } from 'class-validator';

export class CartaWriteDto {
  @IsString()
  titulo: string;

  @IsString()
  conteudo: string;

  @IsOptional()
  @IsDateString()
  data?: string;
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
