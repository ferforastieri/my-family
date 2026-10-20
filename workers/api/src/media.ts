import type { Env } from './env';
import { hmacHex } from './hmac';

export function canSignMedia(env: Env): boolean {
  return Boolean(env.MEDIA_BASE_URL && env.MEDIA_SIGNING_SECRET);
}

export async function signedMediaUrl(env: Env, key: string, expiresIn = 300): Promise<string | null> {
  if (!canSignMedia(env)) return null;
  const expires = Math.floor(Date.now() / 1000) + expiresIn;
  const signature = await hmacHex(env.MEDIA_SIGNING_SECRET!, `${key}:${expires}`);
  return `${env.MEDIA_BASE_URL!.replace(/\/$/, '')}/${key}?expires=${expires}&signature=${signature}`;
}

export async function serveMedia(env: Env, key: string): Promise<Response> {
  const object = await env.MEDIA.get(key);
  if (!object) {
    return new Response(JSON.stringify({ ok: false, message: 'Arquivo não encontrado.' }), {
      status: 404,
      headers: { 'content-type': 'application/json' },
    });
  }
  const headers = new Headers();
  object.writeHttpMetadata(headers);
  headers.set('etag', object.httpEtag);
  headers.set('cache-control', 'private, max-age=300');
  headers.set('content-disposition', 'inline');
  headers.set('x-content-type-options', 'nosniff');
  headers.set('cross-origin-resource-policy', 'cross-origin');
  return new Response(object.body as ReadableStream, { headers });
}
