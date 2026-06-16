import { IsDateString, IsOptional, IsString } from 'class-validator';

export class NotaWriteDto {
  @IsString()
  titulo: string;

  @IsString()
  conteudo: string;

  @IsOptional()
  @IsDateString()
  data?: string;
}

export class NotaResponseDto {
  id: string;
  titulo: string;
  conteudo: string;
  data: Date;
  createdAt: Date;
  updatedAt: Date;
}
