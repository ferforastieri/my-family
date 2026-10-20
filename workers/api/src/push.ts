import { importPKCS8, SignJWT } from 'jose';
import type { Env } from './env';
import { execute, queryAll } from './db';

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

interface Subscription {
  id: string;
  fcm_token: string;
  user_id: string | null;
}

export interface PushPayload {
  title: string;
  body: string;
  url?: string;
  type?: string;
  conversationId?: string;
  senderId?: string;
  senderName?: string;
  channelId?: string;
  includeNotification?: boolean;
}

interface PushResult {
  sent: number;
  deliveredUserIds: string[];
}

let cachedToken: { token: string; expiresAt: number } | null = null;

function serviceAccount(env: Env): ServiceAccount | null {
  if (!env.FIREBASE_SERVICE_ACCOUNT_JSON) return null;
  try {
    return JSON.parse(env.FIREBASE_SERVICE_ACCOUNT_JSON) as ServiceAccount;
  } catch {
    console.error(JSON.stringify({ level: 'error', message: 'FCM service account inválido' }));
    return null;
  }
}

async function googleAccessToken(env: Env, account: ServiceAccount): Promise<string | null> {
  if (cachedToken && cachedToken.expiresAt > Date.now() + 60_000) {
    return cachedToken.token;
  }
  try {
    const key = await importPKCS8(account.private_key, 'RS256');
    const issuedAt = Math.floor(Date.now() / 1000);
    const assertion = await new SignJWT({
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
    })
      .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
      .setIssuer(account.client_email)
      .setAudience('https://oauth2.googleapis.com/token')
      .setIssuedAt(issuedAt)
      .setExpirationTime(issuedAt + 3600)
      .sign(key);
    const response = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion,
      }),
    });
    if (!response.ok) {
      console.error(
        JSON.stringify({
          level: 'error',
          message: 'Falha ao obter token do FCM',
          status: response.status,
        }),
      );
      return null;
    }
    const data = (await response.json()) as { access_token?: string; expires_in?: number };
    if (!data.access_token) return null;
    cachedToken = {
      token: data.access_token,
      expiresAt: Date.now() + (data.expires_in ?? 3600) * 1000,
    };
    return cachedToken.token;
  } catch (error) {
    console.error(
      JSON.stringify({
        level: 'error',
        message: 'Erro ao assinar JWT do FCM',
        error: error instanceof Error ? error.message : String(error),
      }),
    );
    return null;
  }
}

function messageBody(token: string, payload: PushPayload) {
  const data: Record<string, string> = {
    type: payload.type ?? 'push',
    title: payload.title,
    body: payload.body,
    url: payload.url ?? '/',
  };
  if (payload.conversationId) data.conversationId = payload.conversationId;
  if (payload.senderId) data.senderId = payload.senderId;
  if (payload.senderName) data.senderName = payload.senderName;
  const notification = {
    title: payload.title,
    body: payload.body,
  };
  return {
    message: {
      token,
      data,
      ...(payload.includeNotification === false
        ? {}
        : { notification }),
      android: {
        priority: payload.type === 'chat' ? 'high' : 'normal',
        notification: {
          channel_id: payload.channelId ?? (payload.type === 'chat' ? 'chat_messages' : 'my_family_notifications'),
          sound: 'default',
          ...(payload.conversationId ? { tag: `chat-${payload.conversationId}` } : {}),
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            ...(payload.includeNotification === false
              ? {}
              : { alert: notification }),
            ...(payload.conversationId ? { threadId: `chat-${payload.conversationId}` } : {}),
          },
        },
      },
    },
  };
}

async function deliver(
  env: Env,
  account: ServiceAccount,
  accessToken: string,
  subscriptions: Subscription[],
  payload: PushPayload,
): Promise<PushResult> {
  const deliveredUserIds = new Set<string>();
  let sent = 0;
  await Promise.all(
    subscriptions.map(async (subscription) => {
      try {
        const response = await fetch(
          `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`,
          {
            method: 'POST',
            headers: {
              authorization: `Bearer ${accessToken}`,
              'content-type': 'application/json',
            },
            body: JSON.stringify(messageBody(subscription.fcm_token, payload)),
          },
        );
        if (response.ok) {
          sent += 1;
          if (subscription.user_id) deliveredUserIds.add(subscription.user_id);
          return;
        }
        const text = await response.text();
        if (
          response.status === 404 ||
          text.includes('UNREGISTERED') ||
          text.includes('INVALID_ARGUMENT')
        ) {
          await execute(env.DB, 'DELETE FROM push_subscriptions WHERE id = ?', [
            subscription.id,
          ]);
        } else {
          console.error(
            JSON.stringify({
              level: 'warn',
              message: 'Falha no envio FCM',
              status: response.status,
              body: text.substring(0, 200),
            }),
          );
        }
      } catch (error) {
        console.error(
          JSON.stringify({
            level: 'warn',
            message: 'Erro no envio FCM',
            error: error instanceof Error ? error.message : String(error),
          }),
        );
      }
    }),
  );
  return { sent, deliveredUserIds: [...deliveredUserIds] };
}

export async function sendPushToUsers(
  env: Env,
  tenantId: string,
  userIds: string[],
  payload: PushPayload,
): Promise<PushResult> {
  const account = serviceAccount(env);
  if (!account || userIds.length === 0) return { sent: 0, deliveredUserIds: [] };
  const placeholders = userIds.map(() => '?').join(',');
  const subscriptions = await queryAll<Subscription>(
    env.DB,
    `SELECT id, fcm_token, user_id FROM push_subscriptions
      WHERE tenant_id = ? AND fcm_token IS NOT NULL AND user_id IN (${placeholders})`,
    [tenantId, ...userIds],
  );
  if (!subscriptions.length) return { sent: 0, deliveredUserIds: [] };
  const token = await googleAccessToken(env, account);
  if (!token) return { sent: 0, deliveredUserIds: [] };
  return deliver(env, account, token, subscriptions, payload);
}

export async function sendPushToTenant(
  env: Env,
  tenantId: string,
  payload: PushPayload,
  excludeUserIds: string[] = [],
): Promise<PushResult> {
  const account = serviceAccount(env);
  if (!account) return { sent: 0, deliveredUserIds: [] };
  const subscriptions = await queryAll<Subscription>(
    env.DB,
    `SELECT id, fcm_token, user_id FROM push_subscriptions
      WHERE tenant_id = ? AND fcm_token IS NOT NULL`,
    [tenantId],
  );
  const excluded = new Set(excludeUserIds);
  const filtered = subscriptions.filter(
    (subscription) => !subscription.user_id || !excluded.has(subscription.user_id),
  );
  if (!filtered.length) return { sent: 0, deliveredUserIds: [] };
  const token = await googleAccessToken(env, account);
  if (!token) return { sent: 0, deliveredUserIds: [] };
  return deliver(env, account, token, filtered, payload);
}
