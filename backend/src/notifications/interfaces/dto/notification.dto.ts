import { PartialType } from '@nestjs/mapped-types';
import { Type } from 'class-transformer';
import {
  IsDateString,
  IsIn,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';
import { PaginationMessageDto } from '@shared/interfaces/websocket/websocket.dto';

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

export class NotificationUpdateDto extends PartialType(NotificationCreateDto) {}

export class NotificationUpdateMessageDto {
  @IsString()
  id: string;

  @ValidateNested()
  @Type(() => NotificationUpdateDto)
  data: NotificationUpdateDto;
}

export class NotificationScheduleDto extends NotificationSendDto {
  @IsDateString()
  scheduledAt: string;
}

export class FcmSubscribeRequestDto {
  @ValidateNested()
  @Type(() => FcmSubscriptionDto)
  subscription: FcmSubscriptionDto;

  @IsOptional()
  @IsString()
  userAgent?: string;
}

export class FcmUnsubscribeDto {
  @IsString()
  token: string;
}

export class NotificationListQueryDto extends PaginationMessageDto {
  @IsOptional()
  @IsIn(['manual', 'push', 'chat', 'location', 'letter', 'system'])
  type?: NotificationType;
}

export class ScheduledNotificationListQueryDto extends PaginationMessageDto {
  @IsOptional()
  @IsIn(['pending', 'sent', 'failed', 'cancelled'])
  status?: string;
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
