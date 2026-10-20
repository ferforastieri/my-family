import { Hono } from 'hono';
import { z } from 'zod';
import type { AppEnv } from '../env';
import { authMiddleware, requireAccess } from '../auth';
import { badRequest, envelope, notFound, paginated, parseBody, queryInt } from '../http';
import { execute, iso, jsonArray, now, queryAll, queryOne } from '../db';
import { sendNotification } from '../jobs';
import { broadcastToTenant } from '../realtime-service';

type Ctx = Parameters<typeof envelope>[0];

function pageParams(c: Ctx, defaultLimit = 24, max = 100) {
  return {
    page: queryInt(c.req.query('page'), 1, 100000),
    limit: Math.min(max, queryInt(c.req.query('limit'), defaultLimit, max)),
  };
}

function dateValue(value: string | undefined, fallback: number): number {
  if (!value) return fallback;
  const parsed = new Date(value).getTime();
  if (Number.isNaN(parsed)) throw badRequest('Data inválida.');
  return parsed;
}

const notasRoutes = new Hono<AppEnv>();
notasRoutes.use('*', authMiddleware, requireAccess('notas'));

interface NotaRow {
  id: string;
  titulo: string;
  conteudo: string;
  data: number;
  created_at: number;
  updated_at: number;
}

function notaDto(row: NotaRow) {
  return {
    id: row.id,
    titulo: row.titulo,
    conteudo: row.conteudo,
    data: iso(row.data),
    createdAt: iso(row.created_at),
    updatedAt: iso(row.updated_at),
  };
}

const notaSchema = z.object({
  titulo: z.string(),
  conteudo: z.string(),
  data: z.string().optional(),
});

async function findNota(c: Ctx, id: string): Promise<NotaRow | null> {
  const principal = c.get('principal');
  return queryOne<NotaRow>(c.env.DB, 'SELECT * FROM notas WHERE tenant_id = ? AND id = ?', [
    principal.tenantId,
    id,
  ]);
}

notasRoutes.get('/', async (c) => {
  const principal = c.get('principal');
  const { page, limit } = pageParams(c);
  const [rows, total] = await Promise.all([
    queryAll<NotaRow>(
      c.env.DB,
      'SELECT * FROM notas WHERE tenant_id = ? ORDER BY updated_at DESC LIMIT ? OFFSET ?',
      [principal.tenantId, limit, (page - 1) * limit],
    ),
    queryOne<{ count: number }>(
      c.env.DB,
      'SELECT COUNT(*) AS count FROM notas WHERE tenant_id = ?',
      [principal.tenantId],
    ),
  ]);
  return envelope(c, paginated(rows.map(notaDto), total?.count ?? 0, page, limit));
});

notasRoutes.post('/', async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(c, notaSchema);
  const titulo = body.titulo.trim();
  const conteudo = body.conteudo.trim();
  if (!titulo || !conteudo) throw badRequest('Informe título e conteúdo da nota.');
  const id = crypto.randomUUID();
  const timestamp = now();
  const data = dateValue(body.data, timestamp);
  await execute(
    c.env.DB,
    `INSERT INTO notas (id, tenant_id, titulo, conteudo, data, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [id, principal.tenantId, titulo, conteudo, data, timestamp, timestamp],
  );
  const row = await findNota(c, id);
  return envelope(c, { message: 'Nota salva com sucesso.', ...notaDto(row!) });
});

notasRoutes.put('/:id', async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(c, notaSchema.partial());
  const sets: string[] = [];
  const params: unknown[] = [];
  if (body.titulo !== undefined) {
    const value = body.titulo.trim();
    if (!value) throw badRequest('Título não pode ficar vazio.');
    sets.push('titulo = ?');
    params.push(value);
  }
  if (body.conteudo !== undefined) {
    const value = body.conteudo.trim();
    if (!value) throw badRequest('Conteúdo não pode ficar vazio.');
    sets.push('conteudo = ?');
    params.push(value);
  }
  if (body.data !== undefined) {
    sets.push('data = ?');
    params.push(dateValue(body.data, now()));
  }
  if (sets.length) {
    sets.push('updated_at = ?');
    params.push(now(), principal.tenantId, c.req.param('id'));
    await execute(
      c.env.DB,
      `UPDATE notas SET ${sets.join(', ')} WHERE tenant_id = ? AND id = ?`,
      params,
    );
  }
  const row = await findNota(c, c.req.param('id'));
  return envelope(c, row ? { message: 'Nota atualizada.', ...notaDto(row) } : null);
});

notasRoutes.delete('/:id', async (c) => {
  const principal = c.get('principal');
  const result = await execute(
    c.env.DB,
    'DELETE FROM notas WHERE tenant_id = ? AND id = ?',
    [principal.tenantId, c.req.param('id')],
  );
  return envelope(c, { ok: result.meta.changes === 1, message: 'Nota removida.' });
});

interface CartaRow {
  id: string;
  tipo: string;
  titulo: string;
  conteudo: string;
  data: number;
  created_at: number;
  updated_at: number;
}

function cartaDto(row: CartaRow) {
  return {
    id: row.id,
    tipo: row.tipo,
    titulo: row.titulo,
    conteudo: row.conteudo,
    data: iso(row.data),
    createdAt: iso(row.created_at),
    updatedAt: iso(row.updated_at),
  };
}

const cartaSchema = z.object({
  titulo: z.string(),
  conteudo: z.string(),
  data: z.string().optional(),
});

function cartaRoutes(tipo: 'letter' | 'journey', accessKey: 'cartas' | 'nossaHistoria') {
  const routes = new Hono<AppEnv>();
  routes.use('*', authMiddleware, requireAccess(accessKey));

  const find = async (c: Ctx, id: string) => {
    const principal = c.get('principal');
    return queryOne<CartaRow>(
      c.env.DB,
      'SELECT * FROM cartas WHERE tenant_id = ? AND id = ? AND tipo = ?',
      [principal.tenantId, id, tipo],
    );
  };

  routes.get('/', async (c) => {
    const principal = c.get('principal');
    const { page, limit } = pageParams(c);
    const [rows, total] = await Promise.all([
      queryAll<CartaRow>(
        c.env.DB,
        'SELECT * FROM cartas WHERE tenant_id = ? AND tipo = ? ORDER BY data DESC LIMIT ? OFFSET ?',
        [principal.tenantId, tipo, limit, (page - 1) * limit],
      ),
      queryOne<{ count: number }>(
        c.env.DB,
        'SELECT COUNT(*) AS count FROM cartas WHERE tenant_id = ? AND tipo = ?',
        [principal.tenantId, tipo],
      ),
    ]);
    return envelope(c, paginated(rows.map(cartaDto), total?.count ?? 0, page, limit));
  });

  routes.get('/:id', async (c) => {
    const row = await find(c, c.req.param('id'));
    return envelope(c, row ? cartaDto(row) : null);
  });

  routes.post('/', async (c) => {
    const principal = c.get('principal');
    const body = await parseBody(c, cartaSchema);
    const titulo = body.titulo.trim();
    const conteudo = body.conteudo.trim();
    if (!titulo || !conteudo) throw badRequest('Informe título e conteúdo.');
    const id = crypto.randomUUID();
    const timestamp = now();
    const data = dateValue(body.data, timestamp);
    await execute(
      c.env.DB,
      `INSERT INTO cartas (id, tenant_id, tipo, titulo, conteudo, data, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [id, principal.tenantId, tipo, titulo, conteudo, data, timestamp, timestamp],
    );
    const row = await find(c, id);
    if (tipo === 'letter') {
      const authorName = principal.name?.trim() || principal.phoneNumber || 'Alguém';
      await sendNotification(c.env, principal.tenantId, {
        title: 'Nova carta de amor',
        body: `${authorName} escreveu: ${titulo}`,
        url: '/carta-de-amor',
        type: 'letter',
      });
    }
    return envelope(c, {
      message: tipo === 'letter' ? 'Texto salvo.' : 'Capítulo salvo.',
      ...cartaDto(row!),
    });
  });

  routes.put('/:id', async (c) => {
    const principal = c.get('principal');
    const body = await parseBody(c, cartaSchema.partial());
    const sets: string[] = [];
    const params: unknown[] = [];
    if (body.titulo !== undefined) {
      const value = body.titulo.trim();
      if (!value) throw badRequest('Título não pode ficar vazio.');
      sets.push('titulo = ?');
      params.push(value);
    }
    if (body.conteudo !== undefined) {
      const value = body.conteudo.trim();
      if (!value) throw badRequest('Conteúdo não pode ficar vazio.');
      sets.push('conteudo = ?');
      params.push(value);
    }
    if (body.data !== undefined) {
      sets.push('data = ?');
      params.push(dateValue(body.data, now()));
    }
    if (sets.length) {
      sets.push('updated_at = ?');
      params.push(now(), principal.tenantId, tipo, c.req.param('id'));
      await execute(
        c.env.DB,
        `UPDATE cartas SET ${sets.join(', ')} WHERE tenant_id = ? AND tipo = ? AND id = ?`,
        params,
      );
    }
    const row = await find(c, c.req.param('id'));
    return envelope(
      c,
      row
        ? { message: tipo === 'letter' ? 'Texto atualizado.' : 'Capítulo atualizado.', ...cartaDto(row) }
        : null,
    );
  });

  routes.delete('/:id', async (c) => {
    const principal = c.get('principal');
    const result = await execute(
      c.env.DB,
      'DELETE FROM cartas WHERE tenant_id = ? AND tipo = ? AND id = ?',
      [principal.tenantId, tipo, c.req.param('id')],
    );
    return envelope(c, {
      ok: result.meta.changes === 1,
      message: tipo === 'letter' ? 'Texto removido.' : 'Capítulo removido.',
    });
  });

  return routes;
}

interface MusicaRow {
  id: string;
  titulo: string;
  artista: string;
  link_spotify: string;
  descricao: string | null;
  momento: string;
  data: number;
  created_at: number;
  updated_at: number;
}

function musicaDto(row: MusicaRow) {
  return {
    id: row.id,
    titulo: row.titulo,
    artista: row.artista,
    linkSpotify: row.link_spotify,
    descricao: row.descricao,
    momento: row.momento,
    data: iso(row.data),
    createdAt: iso(row.created_at),
    updatedAt: iso(row.updated_at),
  };
}

const musicaSchema = z.object({
  titulo: z.string(),
  artista: z.string(),
  linkSpotify: z.string(),
  momento: z.string(),
  descricao: z.string().optional(),
  data: z.string().optional(),
});

const musicasRoutes = new Hono<AppEnv>();
musicasRoutes.use('*', authMiddleware, requireAccess('playlist'));

const findMusica = async (c: Ctx, id: string) => {
  const principal = c.get('principal');
  return queryOne<MusicaRow>(
    c.env.DB,
    'SELECT * FROM musicas WHERE tenant_id = ? AND id = ?',
    [principal.tenantId, id],
  );
};

musicasRoutes.get('/', async (c) => {
  const principal = c.get('principal');
  const { page, limit } = pageParams(c);
  const [rows, total] = await Promise.all([
    queryAll<MusicaRow>(
      c.env.DB,
      'SELECT * FROM musicas WHERE tenant_id = ? ORDER BY data DESC LIMIT ? OFFSET ?',
      [principal.tenantId, limit, (page - 1) * limit],
    ),
    queryOne<{ count: number }>(
      c.env.DB,
      'SELECT COUNT(*) AS count FROM musicas WHERE tenant_id = ?',
      [principal.tenantId],
    ),
  ]);
  return envelope(c, paginated(rows.map(musicaDto), total?.count ?? 0, page, limit));
});

musicasRoutes.get('/:id', async (c) => {
  const row = await findMusica(c, c.req.param('id'));
  return envelope(c, row ? musicaDto(row) : null);
});

musicasRoutes.post('/', async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(c, musicaSchema);
  const titulo = body.titulo.trim();
  const artista = body.artista.trim();
  const linkSpotify = body.linkSpotify.trim();
  const momento = body.momento.trim();
  const missing = [
    !titulo && 'título',
    !artista && 'artista',
    !linkSpotify && 'link do Spotify',
    !momento && 'momento',
  ].filter(Boolean);
  if (missing.length) throw badRequest(`Informe ${missing.join(', ')}.`);
  const id = crypto.randomUUID();
  const timestamp = now();
  await execute(
    c.env.DB,
    `INSERT INTO musicas (id, tenant_id, titulo, artista, link_spotify, descricao, momento, data, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      id,
      principal.tenantId,
      titulo,
      artista,
      linkSpotify,
      body.descricao?.trim() || null,
      momento,
      dateValue(body.data, timestamp),
      timestamp,
      timestamp,
    ],
  );
  const row = await findMusica(c, id);
  return envelope(c, { message: 'Música salva com sucesso.', ...musicaDto(row!) });
});

musicasRoutes.put('/:id', async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(c, musicaSchema.partial());
  const sets: string[] = [];
  const params: unknown[] = [];
  const labels: Record<string, string> = {
    titulo: 'título',
    artista: 'artista',
    linkSpotify: 'link do Spotify',
    momento: 'momento',
  };
  for (const field of ['titulo', 'artista', 'linkSpotify', 'momento'] as const) {
    if (body[field] !== undefined) {
      const value = body[field]!.trim();
      if (!value) throw badRequest(`${labels[field]} não pode ficar vazio.`);
      sets.push(`${field === 'linkSpotify' ? 'link_spotify' : field} = ?`);
      params.push(value);
    }
  }
  if (body.descricao !== undefined) {
    sets.push('descricao = ?');
    params.push(body.descricao.trim() || null);
  }
  if (body.data !== undefined) {
    sets.push('data = ?');
    params.push(dateValue(body.data, now()));
  }
  if (sets.length) {
    sets.push('updated_at = ?');
    params.push(now(), principal.tenantId, c.req.param('id'));
    await execute(
      c.env.DB,
      `UPDATE musicas SET ${sets.join(', ')} WHERE tenant_id = ? AND id = ?`,
      params,
    );
  }
  const row = await findMusica(c, c.req.param('id'));
  return envelope(c, row ? { message: 'Música atualizada.', ...musicaDto(row) } : null);
});

musicasRoutes.delete('/:id', async (c) => {
  const principal = c.get('principal');
  const result = await execute(
    c.env.DB,
    'DELETE FROM musicas WHERE tenant_id = ? AND id = ?',
    [principal.tenantId, c.req.param('id')],
  );
  return envelope(c, { ok: result.meta.changes === 1, message: 'Música removida.' });
});

// Lists
interface ListRow {
  id: string;
  title: string;
  description: string | null;
  created_by: string | null;
  created_at: number;
  updated_at: number;
}

interface ListItemRow {
  id: string;
  list_id: string;
  text: string;
  checked: number;
  created_by: string | null;
  created_at: number;
  updated_at: number;
}

function listDto(row: ListRow) {
  return {
    id: row.id,
    title: row.title,
    description: row.description,
    createdBy: row.created_by,
    createdAt: iso(row.created_at),
    updatedAt: iso(row.updated_at),
  };
}

function listItemDto(row: ListItemRow) {
  return {
    id: row.id,
    listId: row.list_id,
    text: row.text,
    checked: row.checked === 1,
    createdBy: row.created_by,
    createdAt: iso(row.created_at),
    updatedAt: iso(row.updated_at),
  };
}

const listSchema = z.object({
  title: z.string(),
  description: z.string().nullish(),
});

const listItemSchema = z.object({
  listId: z.string(),
  text: z.string(),
  checked: z.boolean().optional(),
});

const listsRoutes = new Hono<AppEnv>();
listsRoutes.use('*', authMiddleware, requireAccess('listas'));

const findList = async (c: Ctx, id: string) => {
  const principal = c.get('principal');
  return queryOne<ListRow>(
    c.env.DB,
    'SELECT * FROM family_lists WHERE tenant_id = ? AND id = ?',
    [principal.tenantId, id],
  );
};

listsRoutes.get('/', async (c) => {
  const principal = c.get('principal');
  const { page, limit } = pageParams(c, 20, 100);
  const [rows, total] = await Promise.all([
    queryAll<ListRow>(
      c.env.DB,
      'SELECT * FROM family_lists WHERE tenant_id = ? ORDER BY updated_at DESC LIMIT ? OFFSET ?',
      [principal.tenantId, limit, (page - 1) * limit],
    ),
    queryOne<{ count: number }>(
      c.env.DB,
      'SELECT COUNT(*) AS count FROM family_lists WHERE tenant_id = ?',
      [principal.tenantId],
    ),
  ]);
  return envelope(c, paginated(rows.map(listDto), total?.count ?? 0, page, limit));
});

listsRoutes.post('/', async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(c, listSchema);
  const title = body.title.trim();
  if (!title) throw badRequest('title é obrigatório');
  const id = crypto.randomUUID();
  const timestamp = now();
  await execute(
    c.env.DB,
    `INSERT INTO family_lists (id, tenant_id, title, description, created_by, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [id, principal.tenantId, title, body.description?.trim() || null, principal.id, timestamp, timestamp],
  );
  const row = (await findList(c, id))!;
  const dto = listDto(row);
  await broadcastToTenant(c.env, principal.tenantId, 'lists.created', dto);
  return envelope(c, { message: 'Lista criada.', ...dto });
});

listsRoutes.put('/:id', async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(c, listSchema.partial());
  const sets: string[] = [];
  const params: unknown[] = [];
  if (body.title !== undefined) {
    const value = body.title.trim();
    if (!value) throw badRequest('title é obrigatório');
    sets.push('title = ?');
    params.push(value);
  }
  if (body.description !== undefined) {
    sets.push('description = ?');
    params.push(body.description?.trim() || null);
  }
  if (sets.length) {
    sets.push('updated_at = ?');
    params.push(now(), principal.tenantId, c.req.param('id'));
    await execute(
      c.env.DB,
      `UPDATE family_lists SET ${sets.join(', ')} WHERE tenant_id = ? AND id = ?`,
      params,
    );
  }
  const row = await findList(c, c.req.param('id'));
  if (!row) return envelope(c, null);
  const dto = listDto(row);
  await broadcastToTenant(c.env, principal.tenantId, 'lists.updated', dto);
  return envelope(c, { message: 'Lista atualizada.', ...dto });
});

listsRoutes.delete('/:id', async (c) => {
  const principal = c.get('principal');
  const id = c.req.param('id');
  const result = await c.env.DB.batch([
    c.env.DB.prepare('DELETE FROM family_list_items WHERE tenant_id = ? AND list_id = ?').bind(
      principal.tenantId,
      id,
    ),
    c.env.DB.prepare('DELETE FROM family_lists WHERE tenant_id = ? AND id = ?').bind(
      principal.tenantId,
      id,
    ),
  ]);
  const ok = (result[1]?.meta.changes ?? 0) === 1;
  if (ok) await broadcastToTenant(c.env, principal.tenantId, 'lists.deleted', { id });
  return envelope(c, { ok, message: 'Lista removida.' });
});

listsRoutes.get('/:listId/items', async (c) => {
  const principal = c.get('principal');
  const { page, limit } = pageParams(c, 50, 100);
  const listId = c.req.param('listId');
  const [rows, total] = await Promise.all([
    queryAll<ListItemRow>(
      c.env.DB,
      `SELECT * FROM family_list_items WHERE tenant_id = ? AND list_id = ?
       ORDER BY checked ASC, created_at DESC LIMIT ? OFFSET ?`,
      [principal.tenantId, listId, limit, (page - 1) * limit],
    ),
    queryOne<{ count: number }>(
      c.env.DB,
      'SELECT COUNT(*) AS count FROM family_list_items WHERE tenant_id = ? AND list_id = ?',
      [principal.tenantId, listId],
    ),
  ]);
  return envelope(c, paginated(rows.map(listItemDto), total?.count ?? 0, page, limit));
});

listsRoutes.post('/:listId/items', async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(c, listItemSchema);
  const text = body.text.trim();
  if (!text) throw badRequest('text é obrigatório');
  const id = crypto.randomUUID();
  const timestamp = now();
  await execute(
    c.env.DB,
    `INSERT INTO family_list_items (id, tenant_id, list_id, text, checked, created_by, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [id, principal.tenantId, c.req.param('listId'), text, body.checked ? 1 : 0, principal.id, timestamp, timestamp],
  );
  await execute(c.env.DB, 'UPDATE family_lists SET updated_at = ? WHERE tenant_id = ? AND id = ?', [
    timestamp,
    principal.tenantId,
    c.req.param('listId'),
  ]);
  const row = (await queryOne<ListItemRow>(
    c.env.DB,
    'SELECT * FROM family_list_items WHERE tenant_id = ? AND id = ?',
    [principal.tenantId, id],
  ))!;
  const dto = listItemDto(row);
  await broadcastToTenant(c.env, principal.tenantId, 'lists.items.created', dto);
  return envelope(c, { message: 'Item adicionado.', ...dto });
});

listsRoutes.put('/items/:id', async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(c, listItemSchema.partial());
  const sets: string[] = [];
  const params: unknown[] = [];
  if (body.text !== undefined) {
    const value = body.text.trim();
    if (!value) throw badRequest('text é obrigatório');
    sets.push('text = ?');
    params.push(value);
  }
  if (body.checked !== undefined) {
    sets.push('checked = ?');
    params.push(body.checked ? 1 : 0);
  }
  if (sets.length) {
    sets.push('updated_at = ?');
    params.push(now(), principal.tenantId, c.req.param('id'));
    await execute(
      c.env.DB,
      `UPDATE family_list_items SET ${sets.join(', ')} WHERE tenant_id = ? AND id = ?`,
      params,
    );
  }
  const row = await queryOne<ListItemRow>(
    c.env.DB,
    'SELECT * FROM family_list_items WHERE tenant_id = ? AND id = ?',
    [principal.tenantId, c.req.param('id')],
  );
  if (!row) return envelope(c, null);
  const dto = listItemDto(row);
  await broadcastToTenant(c.env, principal.tenantId, 'lists.items.updated', dto);
  return envelope(c, { message: 'Item atualizado.', ...dto });
});

listsRoutes.delete('/items/:id', async (c) => {
  const principal = c.get('principal');
  const id = c.req.param('id');
  const row = await queryOne<{ list_id: string }>(
    c.env.DB,
    'SELECT list_id FROM family_list_items WHERE tenant_id = ? AND id = ?',
    [principal.tenantId, id],
  );
  const result = await execute(
    c.env.DB,
    'DELETE FROM family_list_items WHERE tenant_id = ? AND id = ?',
    [principal.tenantId, id],
  );
  const ok = result.meta.changes === 1;
  if (ok) {
    await execute(c.env.DB, 'UPDATE family_lists SET updated_at = ? WHERE tenant_id = ? AND id = ?', [
      now(),
      principal.tenantId,
      row?.list_id ?? '',
    ]);
    await broadcastToTenant(c.env, principal.tenantId, 'lists.items.deleted', {
      id,
      listId: row?.list_id,
    });
  }
  return envelope(c, { ok, message: 'Item removido.' });
});

// Home settings
interface HomeRow {
  events: string;
  gallery_images: string;
  gallery_order: number | null;
  gallery_title: string | null;
  gallery_title_visible: number;
  gallery_title_layout: string;
}

const defaultEvents = [
  {
    title: 'Nossa história',
    icon: '❤️',
    date: new Date('2026-01-01T12:00:00.000Z').getTime(),
    message: 'Edite este cartão com um momento especial da sua família.',
    countDirection: 'forward',
    hidden: false,
  },
  {
    title: 'Uma data especial',
    icon: '✨',
    date: new Date('2026-01-01T12:00:00.000Z').getTime(),
    message: 'Escolha uma data que sua família queira recordar.',
    countDirection: 'forward',
    hidden: false,
  },
  {
    title: 'Próximo capítulo',
    icon: '🌱',
    date: new Date('2026-12-31T12:00:00.000Z').getTime(),
    message: 'Conte os dias para um novo momento em família.',
    countDirection: 'backward',
    hidden: false,
  },
];

function homeDto(row: Partial<HomeRow>) {
  const events = typeof row.events === 'string' ? JSON.parse(row.events) : defaultEvents;
  const galleryOrder = Math.max(
    0,
    Math.min(events.length, Math.floor(row.gallery_order ?? events.length)),
  );
  return {
    events: (events as Array<Record<string, unknown>>).map((event) => ({
      title: event.title,
      icon: event.icon,
      date: new Date(Number(event.date)).toISOString(),
      message: event.message,
      hidden: event.hidden === true,
      countDirection: event.countDirection === 'backward' ? 'backward' : 'forward',
    })),
    galleryImages: typeof row.gallery_images === 'string' ? jsonArray(row.gallery_images) : [],
    galleryOrder,
    galleryTitle: (row.gallery_title ?? 'Nossas memórias').trim() || 'Nossas memórias',
    galleryTitleVisible: row.gallery_title_visible !== 0,
    galleryTitleLayout: row.gallery_title_layout === 'straight' ? 'straight' : 'arc',
  };
}

const homeSchema = z.object({
  events: z.array(
    z.object({
      title: z.string().optional(),
      icon: z.string().optional(),
      date: z.string().optional(),
      message: z.string().optional(),
      countDirection: z.string().optional(),
      hidden: z.boolean().optional(),
    }),
  ),
  galleryImages: z.array(z.string()).optional(),
  galleryOrder: z.number().optional(),
  galleryTitle: z.string().optional(),
  galleryTitleVisible: z.boolean().optional(),
  galleryTitleLayout: z.string().optional(),
});

const homeRoutes = new Hono<AppEnv>();
homeRoutes.use('*', authMiddleware);

homeRoutes.get('/', async (c) => {
  const principal = c.get('principal');
  const row = await queryOne<HomeRow>(
    c.env.DB,
    'SELECT * FROM home_settings WHERE tenant_id = ? AND key = ?',
    [principal.tenantId, 'home'],
  );
  if (row?.events) return envelope(c, homeDto(row));
  const timestamp = now();
  await execute(
    c.env.DB,
    `INSERT INTO home_settings (id, tenant_id, key, events, gallery_images, gallery_order, gallery_title, gallery_title_visible, gallery_title_layout, created_at, updated_at)
     VALUES (?, ?, 'home', ?, '[]', ?, 'Nossas memórias', 1, 'arc', ?, ?)`,
    [crypto.randomUUID(), principal.tenantId, JSON.stringify(defaultEvents), defaultEvents.length, timestamp, timestamp],
  );
  return envelope(c, homeDto({ events: JSON.stringify(defaultEvents) }));
});

homeRoutes.put('/', async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(c, homeSchema);
  if (!Array.isArray(body.events) || body.events.length < 1) {
    throw badRequest('Informe pelo menos um card da Home.');
  }
  const events = body.events.map((event, index) => {
    const title = event.title?.trim();
    const icon = event.icon?.trim();
    const message = event.message?.trim();
    const date = new Date(event.date ?? '');
    if (!title || !icon || !message || Number.isNaN(date.getTime())) {
      throw badRequest(`Preencha corretamente o evento ${index + 1}.`);
    }
    return {
      title,
      icon,
      message,
      date: date.getTime(),
      countDirection: event.countDirection === 'backward' ? 'backward' : 'forward',
      hidden: event.hidden === true,
    };
  });
  const galleryImages = (body.galleryImages ?? []).map((image) => image.trim()).filter(Boolean);
  const galleryOrder = Math.max(
    0,
    Math.min(events.length, Math.floor(body.galleryOrder ?? events.length)),
  );
  const galleryTitle = body.galleryTitle?.trim() || 'Nossas memórias';
  const galleryTitleVisible = body.galleryTitleVisible !== false;
  const galleryTitleLayout = body.galleryTitleLayout === 'straight' ? 'straight' : 'arc';
  const timestamp = now();
  await execute(
    c.env.DB,
    `INSERT INTO home_settings (id, tenant_id, key, events, gallery_images, gallery_order, gallery_title, gallery_title_visible, gallery_title_layout, created_at, updated_at)
     VALUES (?, ?, 'home', ?, ?, ?, ?, ?, ?, ?, ?)
     ON CONFLICT(tenant_id, key) DO UPDATE SET
       events = excluded.events,
       gallery_images = excluded.gallery_images,
       gallery_order = excluded.gallery_order,
       gallery_title = excluded.gallery_title,
       gallery_title_visible = excluded.gallery_title_visible,
       gallery_title_layout = excluded.gallery_title_layout,
       updated_at = excluded.updated_at`,
    [
      crypto.randomUUID(),
      principal.tenantId,
      JSON.stringify(events),
      JSON.stringify(galleryImages),
      galleryOrder,
      galleryTitle,
      galleryTitleVisible ? 1 : 0,
      galleryTitleLayout,
      timestamp,
      timestamp,
    ],
  );
  return envelope(c, {
    message: 'Datas da Home atualizadas.',
    ...homeDto({
      events: JSON.stringify(events),
      gallery_images: JSON.stringify(galleryImages),
      gallery_order: galleryOrder,
      gallery_title: galleryTitle,
      gallery_title_visible: galleryTitleVisible ? 1 : 0,
      gallery_title_layout: galleryTitleLayout,
    }),
  });
});

export {
  notasRoutes,
  cartaRoutes,
  musicasRoutes,
  listsRoutes,
  homeRoutes,
  pageParams,
};
