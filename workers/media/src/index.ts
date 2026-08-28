interface Env {
  MEDIA: R2Bucket;
  MEDIA_SIGNING_SECRET: string;
  ALLOWED_ORIGIN: string;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (request.method === 'OPTIONS') {
      return cors(new Response(null, { status: 204 }), env);
    }
    if (request.method !== 'GET' && request.method !== 'HEAD') {
      return new Response('Method not allowed', { status: 405 });
    }
    return privateObject(request, url, env);
  },
};

async function privateObject(request: Request, url: URL, env: Env) {
  if (!env.MEDIA_SIGNING_SECRET || env.MEDIA_SIGNING_SECRET.length < 32) {
    return new Response('Worker not configured', { status: 503 });
  }
  let key: string;
  try {
    key = decodeURIComponent(url.pathname.replace(/^\//, ''));
  } catch {
    return new Response('Invalid path', { status: 400 });
  }
  const expires = Number(url.searchParams.get('expires'));
  const signature = url.searchParams.get('signature') ?? '';
  const now = Math.floor(Date.now() / 1000);
  if (
    !key.startsWith('tenants/') ||
    !Number.isFinite(expires) ||
    expires < now ||
    expires > now + 300
  ) {
    return new Response('Expired', { status: 403 });
  }
  if (
    !(await validSignature(
      `${key}:${expires}`,
      signature,
      env.MEDIA_SIGNING_SECRET,
    ))
  ) {
    return new Response('Forbidden', { status: 403 });
  }
  const object = await env.MEDIA.get(key);
  if (!object) return new Response('Not found', { status: 404 });
  const headers = new Headers();
  object.writeHttpMetadata(headers);
  headers.set('etag', object.httpEtag);
  headers.set('cache-control', 'private, max-age=300');
  headers.set('content-disposition', 'inline');
  headers.set('x-content-type-options', 'nosniff');
  headers.set('cross-origin-resource-policy', 'cross-origin');
  return cors(
    new Response(request.method === 'HEAD' ? null : object.body, { headers }),
    env,
  );
}

async function validSignature(value: string, provided: string, secret: string) {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const expected = [
    ...new Uint8Array(
      await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(value)),
    ),
  ]
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
  if (expected.length !== provided.length) return false;
  let mismatch = 0;
  for (let i = 0; i < expected.length; i++) {
    mismatch |= expected.charCodeAt(i) ^ provided.charCodeAt(i);
  }
  return mismatch === 0;
}

function cors(response: Response, env: Env) {
  const next = new Response(response.body, response);
  next.headers.set('access-control-allow-origin', env.ALLOWED_ORIGIN);
  next.headers.set('access-control-allow-methods', 'GET,HEAD,OPTIONS');
  next.headers.set('vary', 'Origin');
  return next;
}
