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

export interface LocationPlaceEntity {
  id: string;
  name: string;
  description?: string | null;
  latitude: number;
  longitude: number;
  radiusMeters: number;
  active: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface LocationPresenceEntity {
  id: string;
  userId: string;
  placeId: string;
  inside: boolean;
  userName?: string | null;
  placeName?: string | null;
  createdAt: Date;
  updatedAt: Date;
}
