export interface NotificationEntity {
  id: string;
  title: string;
  body: string;
  url: string;
  icon?: string | null;
  type: 'manual' | 'push' | 'chat' | 'location' | 'system';
  readBy: string[];
  createdAt: Date;
}

export interface PushSubscriptionEntity {
  id: string;
  fcmToken?: string | null;
  userId?: string | null;
  platform?: 'web' | 'android' | 'ios' | 'unknown' | null;
  userAgent?: string | null;
  createdAt: Date;
}
