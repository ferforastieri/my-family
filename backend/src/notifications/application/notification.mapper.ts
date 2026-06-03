import type { Mapper } from '@shared/application/mapper';
import { NotificationResponseDto } from '../interfaces/dto/notification.dto';

export type NotificationMapperSource = {
  id: string;
  title: string;
  body: string;
  url: string;
  icon?: string | null;
  createdAt: Date;
};

export class NotificationMapper implements Mapper<
  NotificationMapperSource,
  NotificationResponseDto
> {
  toDto(source: NotificationMapperSource): NotificationResponseDto {
    return {
      id: source.id,
      title: source.title,
      body: source.body,
      url: source.url,
      icon: source.icon,
      at: new Date(source.createdAt).getTime(),
    };
  }
}

export const notificationMapper = new NotificationMapper();
