import { Hono } from 'hono';
import { z } from 'zod';
import type { AppEnv } from '../env';
import { authMiddleware, requireAccess } from '../auth';
import { badRequest, envelope, notFound, paginated, parseBody, queryInt } from '../http';
import { execute, iso, now, queryAll, queryOne } from '../db';
import { serveMedia, signedMediaUrl } from '../media';
import { hmacHex } from '../otp';

interface FotoRow {
  id: string;
  url: string;
  texto: string | null;
  album: string | null;
  tipo: string;
  data: number | null;
  created_at: number;
  updated_at: number;
}

function fotoDto(row: FotoRow) {
  return {
    id: row.id,
    url: row.url,
    texto: row.texto,
    album: row.album,
    tipo: row.tipo,
    data: iso(row.data),
    createdAt: iso(row.created_at),
    updatedAt: iso(row.updated_at),
  };
}

const fotoSchema = z.object({
  url: z.string(),
  tipo: z.enum(['imagem', 'video']),
  texto: z.string().optional(),
  album: z.string().optional(),
  data: z.string().optional(),
});

const fotosRoutes = new Hono<AppEnv>();
fotosRoutes.use('*', authMiddleware, requireAccess('memorias'));

const allowedImage = /^image\/(jpeg|png|webp|gif)$/;
const allowedVideo = /^video\/(mp4|webm)$/;

function extensionFor(mime: string): string {
  switch (mime) {
    case 'image/jpeg':
      return '.jpg';
    case 'image/png':
      return '.png';
    case 'image/webp':
      return '.webp';
    case 'image/gif':
      return '.gif';
    case 'video/mp4':
      return '.mp4';
    case 'video/webm':
      return '.webm';
    default:
      return '';
  }
}

const findFoto = async (c: Parameters<typeof envelope>[0], id: string) => {
  const principal = c.get('principal');
  return queryOne<FotoRow>(c.env.DB, 'SELECT * FROM fotos WHERE tenant_id = ? AND id = ?', [
    principal.tenantId,
    id,
  ]);
};

function albumFilter(album?: string) {
  const value = album?.trim();
  if (!value) return { sql: '', params: [] as unknown[] };
  if (value === 'Geral') {
    return {
      sql: ` AND (album IS NULL OR album = '' OR album = 'Geral')`,
      params: [] as unknown[],
    };
  }
  return { sql: ' AND album = ?', params: [value] as unknown[] };
}

fotosRoutes.get('/', async (c) => {
  const principal = c.get('principal');
  const page = queryInt(c.req.query('page'), 1, 100000);
  const limit = Math.min(100, queryInt(c.req.query('limit'), 24, 100));
  const filter = albumFilter(c.req.query('album'));
  const [rows, total] = await Promise.all([
    queryAll<FotoRow>(
      c.env.DB,
      `SELECT * FROM fotos WHERE tenant_id = ?${filter.sql}
       ORDER BY data DESC, created_at DESC LIMIT ? OFFSET ?`,
      [principal.tenantId, ...filter.params, limit, (page - 1) * limit],
    ),
    queryOne<{ count: number }>(
      c.env.DB,
      `SELECT COUNT(*) AS count FROM fotos WHERE tenant_id = ?${filter.sql}`,
      [principal.tenantId, ...filter.params],
    ),
  ]);
  return envelope(c, paginated(rows.map(fotoDto), total?.count ?? 0, page, limit));
});

fotosRoutes.get('/albums', async (c) => {
  const principal = c.get('principal');
  const rows = await queryAll<{ album: string | null; count: number }>(
    c.env.DB,
    'SELECT album, COUNT(*) AS count FROM fotos WHERE tenant_id = ? GROUP BY album',
    [principal.tenantId],
  );
  const counts = new Map<string, number>();
  for (const row of rows) {
    const album = row.album?.trim() || 'Geral';
    counts.set(album, (counts.get(album) ?? 0) + row.count);
  }
  return envelope(
    c,
    [...counts.entries()]
      .map(([album, count]) => ({ album, count }))
      .sort((a, b) => a.album.localeCompare(b.album, 'pt-BR')),
  );
});

fotosRoutes.get('/file-url', async (c) => {
  const path = c.req.query('path');
  if (!path) throw badRequest('Caminho inválido');
  return envelope(c, { url: await signedMediaUrl(c.env, path) });
});

fotosRoutes.get('/file', async (c) => {
  const principal = c.get('principal');
  const path = c.req.query('path');
  if (!path) throw badRequest('Caminho inválido');
  if (!path.startsWith(`tenants/${principal.tenantId}/`)) throw badRequest('Caminho inválido');
  const signed = await signedMediaUrl(c.env, path);
  if (signed) return c.redirect(signed, 302);
  return serveMedia(c.env, path);
});

fotosRoutes.post('/upload', async (c) => {
  const principal = c.get('principal');
  let form: FormData;
  try {
    form = await c.req.formData();
  } catch {
    throw badRequest('Nenhum arquivo enviado');
  }
  const file = form.get('file');
  if (!(file instanceof File)) throw badRequest('Nenhum arquivo enviado');
  const mime = file.type.toLowerCase();
  if (!allowedImage.test(mime) && !allowedVideo.test(mime)) {
    throw badRequest('Tipo de arquivo não permitido');
  }
  const maxSize = mime.startsWith('video/') ? 100_000_000 : 25_000_000;
  if (file.size > maxSize) throw badRequest('Arquivo excede o limite permitido');
  const extension = extensionFor(mime);
  if (!extension) throw badRequest('Tipo de arquivo inválido');
  const key = `tenants/${principal.tenantId}/fotos/${crypto.randomUUID()}${extension}`;
  await c.env.MEDIA.put(key, await file.arrayBuffer(), {
    httpMetadata: { contentType: mime },
  });
  return envelope(c, {
    relativePath: key,
    message: 'Arquivo enviado com sucesso.',
  });
});

fotosRoutes.post('/upload-url', async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(c, z.object({ contentType: z.string() }));
  const mime = body.contentType.toLowerCase();
  if (!allowedImage.test(mime) && !allowedVideo.test(mime)) {
    throw badRequest('Tipo de arquivo não permitido');
  }
  const extension = extensionFor(mime);
  const key = `quarantine/${principal.tenantId}/fotos/${crypto.randomUUID()}${extension}`;
  const expires = Math.floor(Date.now() / 1000) + 300;
  const secret = c.env.MEDIA_SIGNING_SECRET ?? c.env.JWT_SECRET;
  const signature = await hmacHex(secret, `${key}:${expires}`);
  const url = new URL(`/api/uploads/${key}`, c.req.url);
  url.searchParams.set('expires', String(expires));
  url.searchParams.set('signature', signature);
  return envelope(c, { key, url: url.toString(), expiresIn: 300 });
});

fotosRoutes.post('/upload-complete', async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(c, z.object({ key: z.string() }));
  if (!body.key.startsWith(`quarantine/${principal.tenantId}/`)) {
    throw badRequest('Objeto de quarentena inválido');
  }
  const object = await c.env.MEDIA.get(body.key);
  if (!object) throw badRequest('Arquivo não encontrado');
  const filename = body.key.split('/').pop()!;
  const destination = `tenants/${principal.tenantId}/fotos/${filename}`;
  await c.env.MEDIA.put(destination, object.body, {
    httpMetadata: object.httpMetadata,
  });
  await c.env.MEDIA.delete(body.key);
  return envelope(c, {
    relativePath: destination,
    size: object.size,
    processedAt: new Date().toISOString(),
    storage: 'r2',
    message: 'Arquivo enviado com sucesso.',
  });
});

fotosRoutes.get('/upload-status/:jobId', async (c) => {
  return envelope(c, {
    id: c.req.param('jobId'),
    state: 'completed',
    progress: 100,
    result: null,
  });
});

fotosRoutes.get('/:id', async (c) => {
  const row = await findFoto(c, c.req.param('id'));
  return envelope(c, row ? fotoDto(row) : null);
});

fotosRoutes.post('/', async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(c, fotoSchema);
  const url = body.url.trim();
  if (!url) throw badRequest('url é obrigatória');
  const id = crypto.randomUUID();
  const timestamp = now();
  const data = body.data ? new Date(body.data).getTime() : null;
  if (body.data && Number.isNaN(data)) throw badRequest('Data inválida.');
  await execute(
    c.env.DB,
    `INSERT INTO fotos (id, tenant_id, url, texto, album, tipo, data, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      id,
      principal.tenantId,
      url,
      body.texto?.trim() || null,
      body.album?.trim() || null,
      body.tipo,
      data,
      timestamp,
      timestamp,
    ],
  );
  const row = (await findFoto(c, id))!;
  return envelope(c, { message: 'Memória salva com sucesso.', ...fotoDto(row) });
});

fotosRoutes.put('/:id', async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(c, fotoSchema.partial());
  const sets: string[] = [];
  const params: unknown[] = [];
  if (body.url !== undefined) {
    sets.push('url = ?');
    params.push(body.url.trim());
  }
  if (body.tipo !== undefined) {
    sets.push('tipo = ?');
    params.push(body.tipo);
  }
  if (body.texto !== undefined) {
    sets.push('texto = ?');
    params.push(body.texto.trim() || null);
  }
  if (body.album !== undefined) {
    sets.push('album = ?');
    params.push(body.album.trim() || null);
  }
  if (body.data !== undefined) {
    const value = new Date(body.data).getTime();
    if (Number.isNaN(value)) throw badRequest('Data inválida.');
    sets.push('data = ?');
    params.push(value);
  }
  if (sets.length) {
    sets.push('updated_at = ?');
    params.push(now(), principal.tenantId, c.req.param('id'));
    await execute(
      c.env.DB,
      `UPDATE fotos SET ${sets.join(', ')} WHERE tenant_id = ? AND id = ?`,
      params,
    );
  }
  const row = await findFoto(c, c.req.param('id'));
  return envelope(c, row ? { message: 'Memória atualizada.', ...fotoDto(row) } : null);
});

fotosRoutes.delete('/:id', async (c) => {
  const principal = c.get('principal');
  const row = await findFoto(c, c.req.param('id'));
  const result = await execute(c.env.DB, 'DELETE FROM fotos WHERE tenant_id = ? AND id = ?', [
    principal.tenantId,
    c.req.param('id'),
  ]);
  const ok = result.meta.changes === 1;
  if (ok && row?.url?.startsWith(`tenants/${principal.tenantId}/`)) {
    await c.env.MEDIA.delete(row.url).catch(() => undefined);
  }
  return envelope(c, { ok, message: 'Memória removida.' });
});

const uploadsRoutes = new Hono<AppEnv>();

uploadsRoutes.put('/:key{.+}', async (c) => {
  const key = decodeURIComponent(c.req.param('key'));
  if (!key.startsWith('quarantine/')) throw badRequest('Caminho inválido');
  const expires = Number(c.req.query('expires'));
  const signature = c.req.query('signature') ?? '';
  const timestamp = Math.floor(Date.now() / 1000);
  if (!Number.isFinite(expires) || expires < timestamp || expires > timestamp + 600) {
    throw badRequest('URL expirada.');
  }
  const secret = c.env.MEDIA_SIGNING_SECRET ?? c.env.JWT_SECRET;
  const expected = await hmacHex(secret, `${key}:${expires}`);
  if (expected !== signature) throw badRequest('Assinatura inválida.');
  const mime = (c.req.header('content-type') ?? '').toLowerCase();
  if (!allowedImage.test(mime) && !allowedVideo.test(mime)) {
    throw badRequest('Tipo de arquivo não permitido');
  }
  await c.env.MEDIA.put(key, c.req.raw.body, {
    httpMetadata: { contentType: mime },
  });
  return c.json({ ok: true, key });
});

export { fotosRoutes, uploadsRoutes };
