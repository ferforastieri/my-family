import { Hono } from 'hono';
import { createMiddleware } from 'hono/factory';
import { z } from 'zod';
import type { AppEnv } from '../env';
import { authMiddleware, demoRestricted, requireAccess } from '../auth';
import {
  badRequest,
  envelope,
  paginated,
  parseBody,
  queryInt,
  unauthorized,
} from '../http';
import { execute, iso, now, queryAll, queryOne } from '../db';
import { broadcastToTenant } from '../realtime-service';
import { sendNotification } from '../jobs';
import { principalFromLocationToken } from '../location-token';

interface LatestRow {
  tenant_id: string;
  user_id: string;
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
  last_battery_alert_at: number | null;
  updated_at: number;
  email: string | null;
  name: string | null;
  avatar_path: string | null;
}

interface PlaceRow {
  id: string;
  name: string;
  description: string | null;
  latitude: number;
  longitude: number;
  radius_meters: number;
  active: number;
  notify_on_arrive: number;
  notify_on_leave: number;
  created_at: number;
  updated_at: number;
}

function locationDto(row: LatestRow) {
  return {
    id: row.user_id,
    userId: row.user_id,
    userName: row.name ?? row.user_name ?? row.email ?? null,
    email: row.email,
    avatarPath: row.avatar_path,
    latitude: row.latitude,
    longitude: row.longitude,
    accuracy: row.accuracy,
    altitude: row.altitude,
    speed: row.speed,
    heading: row.heading,
    batteryLevel: row.battery_level,
    isCharging: row.is_charging === null ? null : row.is_charging === 1,
    platform: row.platform,
    createdAt: iso(row.updated_at),
    updatedAt: iso(row.updated_at),
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
    notifyOnArrive: row.notify_on_arrive === 1,
    notifyOnLeave: row.notify_on_leave === 1,
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
  platform: z.enum(['android', 'ios', 'web', 'unknown']).optional(),
});

const placeSchema = z.object({
  name: z.string(),
  description: z.string().optional(),
  latitude: z.number(),
  longitude: z.number(),
  radiusMeters: z.number().min(20).max(5000),
  active: z.boolean().optional(),
  notifyOnArrive: z.boolean().optional(),
  notifyOnLeave: z.boolean().optional(),
});

async function getLatestRows(env: AppEnv['Bindings'], tenantId: string) {
  return queryAll<LatestRow>(
    env.DB,
    `SELECT l.*, u.email, u.name, u.avatar_path
       FROM location_latest l
       LEFT JOIN users u ON u.id = l.user_id
      WHERE l.tenant_id = ?
      ORDER BY l.updated_at DESC`,
    [tenantId],
  );
}

async function getLatestRow(
  env: AppEnv['Bindings'],
  tenantId: string,
  userId: string,
) {
  return queryOne<LatestRow>(
    env.DB,
    `SELECT l.*, u.email, u.name, u.avatar_path
       FROM location_latest l
       LEFT JOIN users u ON u.id = l.user_id
      WHERE l.tenant_id = ? AND l.user_id = ?`,
    [tenantId, userId],
  );
}

async function currentPlaceName(
  env: AppEnv['Bindings'],
  tenantId: string,
  row: LatestRow | null,
) {
  if (!row) return null;
  const places = await queryAll<PlaceRow>(
    env.DB,
    'SELECT * FROM location_places WHERE tenant_id = ? AND active = 1',
    [tenantId],
  );
  for (const place of places) {
    if (
      distanceMeters(row.latitude, row.longitude, place.latitude, place.longitude) <=
      place.radius_meters
    ) {
      return place.name;
    }
  }
  return null;
}

function displayName(row: LatestRow) {
  return row.name?.trim() || row.user_name?.trim() || row.email || 'Alguém';
}

async function notifyPlaceTransitions(
  env: AppEnv['Bindings'],
  tenantId: string,
  row: LatestRow,
) {
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
    const notify = inside
      ? place.notify_on_arrive === 1
      : place.notify_on_leave === 1;
    if (!notify) continue;
    const name = displayName(row);
    await sendNotification(env, tenantId, {
      title: 'Localização da família',
      body: inside ? `${name} chegou em ${place.name}.` : `${name} saiu de ${place.name}.`,
      url: '/localizacao',
      type: 'location',
      excludeUserIds: [row.user_id],
    });
  }
}

async function notifyLowBattery(
  env: AppEnv['Bindings'],
  tenantId: string,
  row: LatestRow,
) {
  if (
    row.battery_level === null ||
    row.battery_level > 20 ||
    row.is_charging === 1
  ) {
    return;
  }
  const timestamp = now();
  if (row.last_battery_alert_at && timestamp - row.last_battery_alert_at < 3_600_000) {
    return;
  }
  await execute(
    env.DB,
    'UPDATE location_latest SET last_battery_alert_at = ? WHERE tenant_id = ? AND user_id = ?',
    [timestamp, tenantId, row.user_id],
  );
  await sendNotification(env, tenantId, {
    title: 'Bateria baixa',
    body: `${displayName(row)} está com ${row.battery_level}% de bateria.`,
    url: '/localizacao',
    type: 'location',
    excludeUserIds: [row.user_id],
  });
}

const locationAuth = createMiddleware<AppEnv>(async (c, next) => {
  const header = c.req.header('authorization') ?? '';
  const bearer = /^Bearer\s+(.+)$/i.exec(header)?.[1];
  if (bearer && c.req.method === 'POST' && c.req.path === '/api/location/update') {
    const principal = await principalFromLocationToken(c.env, bearer);
    if (!principal) throw unauthorized('Token de localização inválido.');
    c.set('principal', principal);
    await next();
    return;
  }
  await authMiddleware(c, next);
});

const locationRoutes = new Hono<AppEnv>();
locationRoutes.use('*', locationAuth, requireAccess('localizacao'), demoRestricted);

locationRoutes.post('/update', async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(c, updateSchema);
  if (!Number.isFinite(body.latitude) || !Number.isFinite(body.longitude)) {
    throw badRequest('Localização inválida.');
  }
  const userId = principal.id;
  const userName = principal.name?.trim() || principal.email;
  await execute(
    c.env.DB,
    `INSERT INTO location_latest (
       tenant_id, user_id, user_name, latitude, longitude, accuracy, altitude,
       speed, heading, battery_level, is_charging, platform, updated_at
     ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
     ON CONFLICT(tenant_id, user_id) DO UPDATE SET
       user_name = excluded.user_name,
       latitude = excluded.latitude,
       longitude = excluded.longitude,
       accuracy = excluded.accuracy,
       altitude = excluded.altitude,
       speed = excluded.speed,
       heading = excluded.heading,
       battery_level = excluded.battery_level,
       is_charging = excluded.is_charging,
       platform = excluded.platform,
       updated_at = excluded.updated_at`,
    [
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
      now(),
    ],
  );
  const row = await getLatestRow(c.env, principal.tenantId, userId);
  if (row) {
    await broadcastToTenant(
      c.env,
      principal.tenantId,
      'location.updated',
      locationDto(row),
    );
    await notifyPlaceTransitions(c.env, principal.tenantId, row);
    await notifyLowBattery(c.env, principal.tenantId, row);
  }
  return envelope(c, { id: userId, message: 'Localização atualizada.' });
});

locationRoutes.get('/latest', async (c) => {
  const principal = c.get('principal');
  const page = queryInt(c.req.query('page'), 1, 100000);
  const limit = Math.min(100, queryInt(c.req.query('limit'), 50, 100));
  const rows = await getLatestRows(c.env, principal.tenantId);
  const start = (page - 1) * limit;
  return envelope(
    c,
    paginated(
      rows.slice(start, start + limit).map(locationDto),
      rows.length,
      page,
      limit,
    ),
  );
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
    `INSERT INTO location_places (
       id, tenant_id, name, description, latitude, longitude, radius_meters,
       active, notify_on_arrive, notify_on_leave, created_at, updated_at
     ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      id,
      principal.tenantId,
      name,
      body.description?.trim() || null,
      body.latitude,
      body.longitude,
      Math.max(20, Math.min(5000, Math.round(body.radiusMeters))),
      body.active === false ? 0 : 1,
      body.notifyOnArrive === false ? 0 : 1,
      body.notifyOnLeave === false ? 0 : 1,
      timestamp,
      timestamp,
    ],
  );
  const row = (await queryOne<PlaceRow>(
    c.env.DB,
    'SELECT * FROM location_places WHERE id = ?',
    [id],
  ))!;
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
  if (body.latitude !== undefined) {
    sets.push('latitude = ?');
    params.push(body.latitude);
  }
  if (body.longitude !== undefined) {
    sets.push('longitude = ?');
    params.push(body.longitude);
  }
  if (body.radiusMeters !== undefined) {
    sets.push('radius_meters = ?');
    params.push(Math.max(20, Math.min(5000, Math.round(body.radiusMeters))));
  }
  if (body.active !== undefined) {
    sets.push('active = ?');
    params.push(body.active ? 1 : 0);
  }
  if (body.notifyOnArrive !== undefined) {
    sets.push('notify_on_arrive = ?');
    params.push(body.notifyOnArrive ? 1 : 0);
  }
  if (body.notifyOnLeave !== undefined) {
    sets.push('notify_on_leave = ?');
    params.push(body.notifyOnLeave ? 1 : 0);
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
    c.env.DB.prepare(
      'DELETE FROM location_presences WHERE tenant_id = ? AND place_id = ?',
    ).bind(principal.tenantId, id),
    c.env.DB.prepare(
      'DELETE FROM location_places WHERE tenant_id = ? AND id = ?',
    ).bind(principal.tenantId, id),
  ]);
  const ok = (result[1]?.meta.changes ?? 0) === 1;
  if (ok) {
    await broadcastToTenant(c.env, principal.tenantId, 'location.places.changed', {
      id,
    });
  }
  return envelope(c, { ok, message: 'Local removido.' });
});

locationRoutes.post('/sos', async (c) => {
  const principal = c.get('principal');
  const latest = await getLatestRow(c.env, principal.tenantId, principal.id);
  const place = await currentPlaceName(c.env, principal.tenantId, latest);
  const name = principal.name?.trim() || principal.email;
  await sendNotification(c.env, principal.tenantId, {
    title: `SOS de ${name}`,
    body: place ? `Pedido de ajuda em ${place}.` : 'Pedido de ajuda.',
    url: '/localizacao',
    type: 'location',
    excludeUserIds: [principal.id],
  });
  return envelope(c, { ok: true, message: 'SOS enviado para a família.' });
});

locationRoutes.post('/check-in', async (c) => {
  const principal = c.get('principal');
  const latest = await getLatestRow(c.env, principal.tenantId, principal.id);
  const place = await currentPlaceName(c.env, principal.tenantId, latest);
  const name = principal.name?.trim() || principal.email;
  await sendNotification(c.env, principal.tenantId, {
    title: `Check-in de ${name}`,
    body: place ? `Está bem em ${place}.` : 'Está bem e por aqui.',
    url: '/localizacao',
    type: 'location',
    excludeUserIds: [principal.id],
  });
  return envelope(c, { ok: true, message: 'Check-in enviado para a família.' });
});

export { locationRoutes };
