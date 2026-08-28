import { IsIn, IsOptional, IsString, Length, MaxLength } from 'class-validator';

export class RequestPhoneCodeDto {
  @IsString()
  @MaxLength(32)
  phone: string;

  @IsIn(['whatsapp', 'sms'])
  channel: 'whatsapp' | 'sms';

  @IsString()
  @IsOptional()
  @MaxLength(2048)
  turnstileToken?: string;
}

export class VerifyPhoneCodeDto {
  @IsString()
  @MaxLength(32)
  phone: string;

  @IsString()
  @Length(6, 6)
  code: string;

  @IsString()
  @IsOptional()
  @MaxLength(128)
  invitationToken?: string;

  @IsString()
  @IsOptional()
  @MaxLength(48)
  tenantSlug?: string;
}
