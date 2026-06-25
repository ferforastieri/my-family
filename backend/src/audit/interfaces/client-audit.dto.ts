import { IsObject, IsOptional, IsString, MaxLength } from 'class-validator';

export class ClientAuditDto {
  @IsString()
  @MaxLength(100)
  action: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  path?: string;

  @IsOptional()
  @IsObject()
  metadata?: Record<string, unknown>;
}
