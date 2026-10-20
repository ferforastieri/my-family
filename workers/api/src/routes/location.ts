import { Hono } from 'hono';
import { z } from 'zod';
import type { AppEnv } from '../env';
import { authMiddleware, demoRestricted, requireAccess } from '../auth';
import { badRequest, envelope, paginated, parseBody, queryInt } from '../http';
import { execute, iso, now, queryAll, queryOne } from '../db';
import { broadcastToTenant } from '../realtime-service';
import { sendNotification } from '../jobs';

interface LocationRow {
  id: string;
  user_id: string | null;
  user_name: string | null;
  latitude: number;
  longitude: number;
  accuracy: number | null;
  altitude: number | null;
  speed: number | null;
  heading: number | null;
  battery_level: number | null;
  is_charging: number | null;
  platform: string;
  created_at: number;
}

interface PlaceRow {
  id: string;
  name: string;
  description: string | null;
  latitude: number;
  longitude: number;
  radius_meters: number;
  active: number;
  created_at: number;
  updated_at: number;
}

function locationDto(row: LocationRow) {
  return {
    id: row.id,
    userId: row.user_id,
    userName: row.user_name,
    latitude: row.latitude,
    longitude: row.longitude,
    accuracy: row.accuracy,
    altitude: row.altitude,
    speed: row.speed,
    heading: row.heading,
    batteryLevel: row.battery_level,
    isCharging: row.is_charging === null ? null : row.is_charging === 1,
    platform: row.platform,
    createdAt: iso(row.created_at),
  };
}

function placeDto(row: PlaceRow) {
  return {
    id: row.id,
    name: row.name,
    description: row.description,
    latitude: row.latitude,
    longitude: row.longitude,
    radiusMeters: row.radius_meters,
    active: row.active === 1,
    createdAt: iso(row.created_at),
    updatedAt: iso(row.updated_at),
  };
}

function distanceMeters(lat1: number, lon1: number, lat2: number, lon2: number) {
  const earthRadius = 6371000;
  const toRadians = (value: number) => (value * Math.PI) / 180;
  const phi1 = toRadians(lat1);
  const phi2 = toRadians(lat2);
  const deltaPhi = toRadians(lat2 - lat1);
  const deltaLambda = toRadians(lon2 - lon1);
  const a =
    Math.sin(deltaPhi / 2) ** 2 +
    Math.cos(phi1) * Math.cos(phi2) * Math.sin(deltaLambda / 2) ** 2;
  return earthRadius * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

const updateSchema = z.object({
  latitude: z.number(),
  longitude: z.number(),
  accuracy: z.number().optional(),
  altitude: z.number().optional(),
  speed: z.number().optional(),
  heading: z.number().optional(),
  batteryLevel: z.number().min(0).max(100).optional(),
  isCharging: z.boolean().optional(),
  userId: z.string().optional(),
  userName: z.string().optional(),
  platform: z.enum(['android', 'ios', 'web', 'unknown']).optional(),
});

const placeSchema = z.object({
  name: z.string(),
  description: z.string().optional(),
  latitude: z.number(),
  longitude: z.number(),
  radiusMeters: z.number().min(20).max(5000),
  active: z.boolean().optional(),
});

const locationRoutes = new Hono<AppEnv>();
locationRoutes.use('*', authMiddleware, requireAccess('localizacao'), demoRestricted);

locationRoutes.post('/update', async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(c, updateSchema);
  if (body.platform === 'web') throw badRequest('Localização web não é rastreada.');
  if (!Number.isFinite(body.latitude) || !Number.isFinite(body.longitude)) {
    throw badRequest('Localização inválida.');
  }
  const id = crypto.randomUUID();
  const timestamp = now();
  const userId = principal.id;
  const userName = principal.name || principal.email || body.userName || null;
  await execute(
    c.env.DB,
    `INSERT INTO location_updates (id, tenant_id, user_id, user_name, latitude, longitude, accuracy, altitude, speed, heading, battery_level, is_charging, platform, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      id,
      principal.tenantId,
      userId,
      userName,
      body.latitude,
      body.longitude,
      body.accuracy ?? null,
      body.altitude ?? null,
      body.speed ?? null,
      body.heading ?? null,
      body.batteryLevel ?? null,
      body.isCharging === undefined ? null : body.isCharging ? 1 : 0,
      body.platform ?? 'unknown',
      timestamp,
    ],
  );
  const row = (await queryOne<LocationRow>(
    c.env.DB,
    'SELECT * FROM location_updates WHERE id = ?',
    [id],
  ))!;
  const dto = locationDto(row);
  await broadcastToTenant(c.env, principal.tenantId, 'location.updated', dto);
  await notifyPlaceTransitions(c.env, principal.tenantId, row);
  return envelope(c, { id, message: 'Localização atualizada.' });
});

locationRoutes.get('/latest', async (c) => {
  const principal = c.get('principal');
  const page = queryInt(c.req.query('page'), 1, 100000);
  const limit = Math.min(100, queryInt(c.req.query('limit'), 50, 100));
  const offset = (page - 1) * limit;
  const rows = await queryAll<LocationRow>(
    c.env.DB,
    `SELECT * FROM (
       SELECT *, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC) AS rn
         FROM location_updates
        WHERE tenant_id = ? AND user_id IS NOT NULL AND user_id <> ''
          AND platform IN ('android', 'ios')
     ) WHERE rn = 1 ORDER BY created_at DESC LIMIT ? OFFSET ?`,
    [principal.tenantId, limit, offset],
  );
  const total = await queryOne<{ count: number }>(
    c.env.DB,
    `SELECT COUNT(DISTINCT user_id) AS count FROM location_updates
      WHERE tenant_id = ? AND user_id IS NOT NULL AND user_id <> ''
        AND platform IN ('android', 'ios')`,
    [principal.tenantId],
  );
  return envelope(c, paginated(rows.map(locationDto), total?.count ?? 0, page, limit));
});

locationRoutes.get('/places', async (c) => {
  const principal = c.get('principal');
  const rows = await queryAll<PlaceRow>(
    c.env.DB,
    'SELECT * FROM location_places WHERE tenant_id = ? ORDER BY name ASC, created_at DESC',
    [principal.tenantId],
  );
  return envelope(c, rows.map(placeDto));
});

locationRoutes.post('/places', async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(c, placeSchema);
  const name = body.name.trim();
  if (!name) throw badRequest('Nome do local é obrigatório.');
  const id = crypto.randomUUID();
  const timestamp = now();
  await execute(
    c.env.DB,
    `INSERT INTO location_places (id, tenant_id, name, description, latitude, longitude, radius_meters, active, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      id,
      principal.tenantId,
      name,
      body.description?.trim() ?? null,
      body.latitude,
      body.longitude,
      Math.max(20, Math.min(5000, Math.round(body.radiusMeters))),
      body.active === false ? 0 : 1,
      timestamp,
      timestamp,
    ],
  );
  const row = (await queryOne<PlaceRow>(c.env.DB, 'SELECT * FROM location_places WHERE id = ?', [
    id,
  ]))!;
  const dto = placeDto(row);
  await broadcastToTenant(c.env, principal.tenantId, 'location.places.changed', dto);
  return envelope(c, { message: 'Local salvo.', ...dto });
});

locationRoutes.put('/places/:id', async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(c, placeSchema.partial());
  const sets: string[] = [];
  const params: unknown[] = [];
  if (body.name !== undefined) {
    const value = body.name.trim();
    if (!value) throw badRequest('Nome do local é obrigatório.');
    sets.push('name = ?');
    params.push(value);
  }
  if (body.description !== undefined) {
    sets.push('description = ?');
    params.push(body.description?.trim() || null);
  }
  for (const [field, column] of [
    ['latitude', 'latitude'],
    ['longitude', 'longitude'],
  ] as const) {
    if (body[field] !== undefined) {
      sets.push(`${column} = ?`);
      params.push(body[field]);
    }
  }
  if (body.radiusMeters !== undefined) {
    sets.push('radius_meters = ?');
    params.push(Math.max(20, Math.min(5000, Math.round(body.radiusMeters))));
  }
  if (body.active !== undefined) {
    sets.push('active = ?');
    params.push(body.active ? 1 : 0);
  }
  if (sets.length) {
    sets.push('updated_at = ?');
    params.push(now(), principal.tenantId, c.req.param('id'));
    await execute(
      c.env.DB,
      `UPDATE location_places SET ${sets.join(', ')} WHERE tenant_id = ? AND id = ?`,
      params,
    );
  }
  const row = await queryOne<PlaceRow>(
    c.env.DB,
    'SELECT * FROM location_places WHERE tenant_id = ? AND id = ?',
    [principal.tenantId, c.req.param('id')],
  );
  if (!row) return envelope(c, null);
  const dto = placeDto(row);
  await broadcastToTenant(c.env, principal.tenantId, 'location.places.changed', dto);
  return envelope(c, { message: 'Local atualizado.', ...dto });
});

locationRoutes.delete('/places/:id', async (c) => {
  const principal = c.get('principal');
  const id = c.req.param('id');
  const result = await c.env.DB.batch([
    c.env.DB.prepare('DELETE FROM location_presences WHERE tenant_id = ? AND place_id = ?').bind(
      principal.tenantId,
      id,
    ),
    c.env.DB.prepare('DELETE FROM location_places WHERE tenant_id = ? AND id = ?').bind(
      principal.tenantId,
      id,
    ),
  ]);
  const ok = (result[1]?.meta.changes ?? 0) === 1;
  if (ok) {
    await broadcastToTenant(c.env, principal.tenantId, 'location.places.changed', { id });
  }
  return envelope(c, { ok, message: 'Local removido.' });
});

async function notifyPlaceTransitions(env: AppEnv['Bindings'], tenantId: string, row: LocationRow) {
  if (!row.user_id) return;
  const places = await queryAll<PlaceRow>(
    env.DB,
    'SELECT * FROM location_places WHERE tenant_id = ? AND active = 1',
    [tenantId],
  );
  for (const place of places) {
    const inside =
      distanceMeters(row.latitude, row.longitude, place.latitude, place.longitude) <=
      place.radius_meters;
    const previous = await queryOne<{ inside: number }>(
      env.DB,
      'SELECT inside FROM location_presences WHERE tenant_id = ? AND user_id = ? AND place_id = ?',
      [tenantId, row.user_id, place.id],
    );
    if (previous && (previous.inside === 1) === inside) continue;
    const timestamp = now();
    await execute(
      env.DB,
      `INSERT INTO location_presences (id, tenant_id, user_id, place_id, inside, user_name, place_name, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
       ON CONFLICT(tenant_id, user_id, place_id) DO UPDATE SET
         inside = excluded.inside,
         user_name = excluded.user_name,
         place_name = excluded.place_name,
         updated_at = excluded.updated_at`,
      [
        crypto.randomUUID(),
        tenantId,
        row.user_id,
        place.id,
        inside ? 1 : 0,
        row.user_name,
        place.name,
        timestamp,
        timestamp,
      ],
    );
    if (!previous) continue;
    const name = row.user_name || 'Alguém';
    await sendNotification(env, tenantId, {
      title: 'Localização da família',
      body: inside ? `${name} chegou em ${place.name}.` : `${name} saiu de ${place.name}.`,
      url: '/localizacao',
      type: 'location',
    });
  }
}

export { locationRoutes };
