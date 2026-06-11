import { IsIn, IsOptional, IsString } from 'class-validator';

export type NotificationType =
  | 'manual'
  | 'push'
  | 'chat'
  | 'location'
  | 'letter'
  | 'system';

export class NotificationCreateDto {
  @IsString()
  title: string;

  @IsOptional()
  @IsString()
  body?: string;

  @IsOptional()
  @IsString()
  url?: string;

  @IsOptional()
  @IsString()
  icon?: string;

  @IsOptional()
  @IsIn(['manual', 'push', 'chat', 'location', 'letter', 'system'])
  type?: NotificationType;
}

export class NotificationSendDto {
  @IsString()
  title: string;

  @IsOptional()
  @IsString()
  body?: string;

  @IsOptional()
  @IsString()
  url?: string;
}

export class FcmSubscriptionDto {
  @IsString()
  token: string;

  @IsOptional()
  @IsString()
  @IsIn(['web', 'android', 'ios', 'unknown'])
  platform?: 'web' | 'android' | 'ios' | 'unknown';
}

export class NotificationResponseDto {
  id: string;
  title: string;
  body: string;
  url: string;
  icon?: string | null;
  type: NotificationType;
  read: boolean;
  at: number;
}
