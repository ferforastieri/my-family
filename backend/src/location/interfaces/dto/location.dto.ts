import {
  IsBoolean,
  IsIn,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

export class LocationUpdateDto {
  @IsNumber()
  latitude: number;

  @IsNumber()
  longitude: number;

  @IsNumber()
  @IsOptional()
  accuracy?: number;

  @IsNumber()
  @IsOptional()
  altitude?: number;

  @IsNumber()
  @IsOptional()
  speed?: number;

  @IsNumber()
  @IsOptional()
  heading?: number;

  @IsNumber()
  @Min(0)
  @Max(100)
  @IsOptional()
  batteryLevel?: number;

  @IsBoolean()
  @IsOptional()
  isCharging?: boolean;

  @IsString()
  @IsOptional()
  userId?: string;

  @IsString()
  @IsOptional()
  userName?: string;

  @IsString()
  @IsIn(['android', 'ios', 'web', 'unknown'])
  @IsOptional()
  platform?: 'android' | 'ios' | 'web' | 'unknown';
}

export class LocationResponseDto {
  id: string;
  userId: string | null;
  userName: string | null;
  latitude: number;
  longitude: number;
  accuracy: number | null;
  altitude: number | null;
  speed: number | null;
  heading: number | null;
  batteryLevel: number | null;
  isCharging: boolean | null;
  platform: string;
  createdAt: Date;
}
