import { Hono } from 'hono';
import type { AppEnv } from '../env';

const mapRoutes = new Hono<AppEnv>();

// Public, key-free raster tiles. Cached by Cloudflare so the app never talks to
// a provider that asks for an API key and avoids browser CORS/referrer limits.
mapRoutes.get('/tiles/:z/:x/:y', async (c) => {
  const z = Number(c.req.param('z'));
  const x = Number(c.req.param('x'));
  const y = Number(c.req.param('y'));
  const max = 2 ** Math.min(Math.max(z, 0), 19);
  if (
    !Number.isInteger(z) ||
    !Number.isInteger(x) ||
    !Number.isInteger(y) ||
    z < 0 ||
    z > 19 ||
    x < 0 ||
    y < 0 ||
    x >= max ||
    y >= max
  ) {
    return c.text('Tile inválido', 400);
  }
  const cache = (caches as unknown as { default: Cache }).default;
  // Versioned key: avoids serving the old provider's key-required tiles from
  // edge cache after changing the upstream.
  const cacheKey = new Request(
    `${new URL(c.req.url).origin}/api/map/tiles/${z}/${x}/${y}?v=osm`,
    { method: 'GET' },
  );
  const cached = await cache.match(cacheKey);
  if (cached) return cached;
  const upstream = await fetch(
    `https://tile.openstreetmap.org/${z}/${x}/${y}.png`,
    {
      headers: {
        'User-Agent': 'Siao/1.0 (family map; +https://siao-web.vira-ia-br.workers.dev)',
        Referer: 'https://siao-web.vira-ia-br.workers.dev',
        Accept: 'image/png,image/*;q=0.8',
      },
    },
  );
  if (!upstream.ok) {
    return c.text('Tile indisponível', 502);
  }
  const headers = new Headers();
  headers.set('content-type', upstream.headers.get('content-type') ?? 'image/png');
  headers.set('cache-control', 'public, max-age=86400, immutable');
  headers.set('access-control-allow-origin', '*');
  const response = new Response(upstream.body, { status: 200, headers });
  c.executionCtx.waitUntil(cache.put(cacheKey, response.clone()));
  return response;
});

export { mapRoutes };
