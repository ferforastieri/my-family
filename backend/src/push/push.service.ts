import { Injectable, Inject } from '@nestjs/common';
import * as webPush from 'web-push';
import { DATABASE_CONNECTION } from '@shared/infrastructure/database/database.module';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import type * as schema from '@shared/infrastructure/database/schema';
import { pushSubscriptions } from '@shared/infrastructure/database/schema';
import { eq } from 'drizzle-orm';
import { Environment } from '@shared/infrastructure/environment/environment.module';

export interface PushSubscriptionDto {
  endpoint: string;
  keys: { p256dh: string; auth: string };
  expirationTime?: number | null;
}

@Injectable()
export class PushService {
  private initialized = false;

  constructor(
    @Inject(DATABASE_CONNECTION)
    private db: NodePgDatabase<typeof schema>,
    private env: Environment,
  ) {
    if (this.env.vapidPublicKey && this.env.vapidPrivateKey) {
      webPush.setVapidDetails(
        'mailto:nossa-familia@local',
        this.env.vapidPublicKey,
        this.env.vapidPrivateKey,
      );
      this.initialized = true;
    }
  }

  isEnabled(): boolean {
    return this.initialized;
  }

  getVapidPublicKey(): string | null {
    return this.env.vapidPublicKey ?? null;
  }

  async subscribe(subscription: PushSubscriptionDto, _userAgent?: string): Promise<void> {
    await this.db
      .insert(pushSubscriptions)
      .values({
        endpoint: subscription.endpoint,
        keys: subscription.keys,
      })
      .onConflictDoUpdate({
        target: pushSubscriptions.endpoint,
        set: { keys: subscription.keys },
      });
  }

  async unsubscribe(endpoint: string): Promise<void> {
    await this.db.delete(pushSubscriptions).where(eq(pushSubscriptions.endpoint, endpoint));
  }

  async sendToAll(title: string, body?: string, url?: string): Promise<{ sent: number; failed: number }> {
    if (!this.initialized) return { sent: 0, failed: 0 };
    const payload = JSON.stringify({
      title,
      body: body ?? '',
      url: url ?? '/',
      icon: '/favicon-192.png',
    });
    const subs = await this.db.select().from(pushSubscriptions);
    let sent = 0;
    let failed = 0;
    for (const sub of subs) {
      try {
        await webPush.sendNotification(
          {
            endpoint: sub.endpoint,
            keys: sub.keys as { p256dh: string; auth: string },
          },
          payload,
          { TTL: 86400 },
        );
        sent++;
      } catch {
        failed++;
        try {
          await this.db.delete(pushSubscriptions).where(eq(pushSubscriptions.id, sub.id));
        } catch {
        }
      }
    }
    return { sent, failed };
  }
}
