export interface LocationUpdateEntity {
  id: string;
  userId?: string | null;
  userName?: string | null;
  latitude: number;
  longitude: number;
  accuracy?: number | null;
  altitude?: number | null;
  speed?: number | null;
  heading?: number | null;
  batteryLevel?: number | null;
  isCharging?: boolean | null;
  platform?: 'web' | 'android' | 'ios' | 'unknown' | null;
  createdAt: Date;
}
