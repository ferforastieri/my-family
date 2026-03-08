import { Injectable, Inject } from '@nestjs/common';
import * as webPush from 'web-push';
import { DATABASE_CONNECTION } from '@shared/infrastructure/database/database.module';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import type * as schema from '@shared/infrastructure/database/schema';
import { notifications, pushSubscriptions } from '@shared/infrastructure/database/schema';
import { eq, desc } from 'drizzle-orm';
import { Environment } from '@shared/infrastructure/environment/environment.module';

const LIST_LIMIT = 100;

export interface PushSubscriptionDto {
  endpoint: string;
  keys: { p256dh: string; auth: string };
  expirationTime?: number | null;
}

@Injectable()
export class NotificationsService {
  private pushEnabled = false;

  constructor(
    @Inject(DATABASE_CONNECTION)
    private db: NodePgDatabase<typeof schema>,
    private env: Environment,
  ) {
    if (this.env.vapidPublicKey && this.env.vapidPrivateKey) {
      const wp = (webPush as any).default ?? webPush;
      if (wp?.setVapidDetails) {
        wp.setVapidDetails('mailto:nossa-familia@local', this.env.vapidPublicKey, this.env.vapidPrivateKey);
        this.pushEnabled = true;
      }
    }
  }

  getVapidPublicKey(): string | null {
    return this.env.vapidPublicKey ?? null;
  }

  async list() {
    const rows = await this.db
      .select()
      .from(notifications)
      .orderBy(desc(notifications.createdAt))
      .limit(LIST_LIMIT);
    return rows.map((r) => ({
      id: r.id,
      title: r.title,
      body: r.body,
      url: r.url,
      icon: r.icon,
      at: new Date(r.createdAt).getTime(),
    }));
  }

  async clearAll() {
    await this.db.delete(notifications);
  }

  async pushSubscribe(subscription: PushSubscriptionDto) {
    await this.db
      .insert(pushSubscriptions)
      .values({ endpoint: subscription.endpoint, keys: subscription.keys })
      .onConflictDoUpdate({
        target: pushSubscriptions.endpoint,
        set: { keys: subscription.keys },
      });
  }

  async pushUnsubscribe(endpoint: string) {
    await this.db.delete(pushSubscriptions).where(eq(pushSubscriptions.endpoint, endpoint));
  }

  async send(title: string, body?: string, url?: string): Promise<{ sent: number }> {
    await this.db.insert(notifications).values({
      title: title ?? 'Nossa Família',
      body: body ?? '',
      url: url ?? '/',
      icon: '/favicon-192.png',
    } as any);
    if (!this.pushEnabled) return { sent: 0 };
    const wp = (webPush as any).default ?? webPush;
    const payload = JSON.stringify({
      title: title ?? 'Nossa Família',
      body: body ?? '',
      url: url ?? '/',
      icon: '/favicon-192.png',
    });
    const subs = await this.db.select().from(pushSubscriptions);
    let sent = 0;
    for (const sub of subs) {
      try {
        await wp.sendNotification(
          { endpoint: sub.endpoint, keys: sub.keys as { p256dh: string; auth: string } },
          payload,
          { TTL: 86400 },
        );
        sent++;
      } catch {
        try {
          await this.db.delete(pushSubscriptions).where(eq(pushSubscriptions.id, sub.id));
        } catch {
          //
        }
      }
    }
    return { sent };
  }
}
