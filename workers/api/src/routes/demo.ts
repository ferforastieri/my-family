import { Hono } from 'hono';
import type { AppEnv } from '../env';
import { setSessionCookies } from '../auth';
import { createTenant, createMembership, tokenResponse } from '../tenants';
import { createUser } from '../auth-service';
import { envelope } from '../http';
import { execute, now } from '../db';
import { verifyTurnstile } from '../turnstile';

const demoRoutes = new Hono<AppEnv>();

demoRoutes.post('/', async (c) => {
  let token: string | undefined;
  try {
    const body = (await c.req.json()) as { turnstileToken?: string };
    token = body?.turnstileToken;
  } catch {
    token = undefined;
  }
  await verifyTurnstile(c.env, token, c.req.header('cf-connecting-ip'), {
    required: false,
    action: 'demo',
  });

  const suffix = crypto.randomUUID().slice(0, 8);
  const user = await createUser(c.env, {
    email: `demo-${suffix}@siao.local`,
    password: crypto.randomUUID(),
    name: 'Visitante da demo',
  });
  const tenant = await createTenant(c.env, {
    name: 'Família Aurora',
    slug: `demo-${suffix}`,
    isDemo: true,
    expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
  });
  await createMembership(c.env, {
    tenantId: tenant.id,
    userId: user.id,
    role: 'admin',
    relationship: 'friends',
    access: [
      'memorias',
      'playlist',
      'cartas',
      'jogos',
      'listas',
      'notas',
      'chat',
      'nossaHistoria',
    ],
  });

  const timestamp = now();
  const homeEvents = [
    {
      title: 'Nossa história',
      icon: '❤️',
      date: new Date('2018-05-12').getTime(),
      message: 'O dia em que tudo começou',
      countDirection: 'forward',
      hidden: false,
    },
  ];
  await execute(
    c.env.DB,
    `INSERT INTO home_settings (id, tenant_id, key, events, gallery_images, gallery_order, gallery_title, gallery_title_visible, gallery_title_layout, created_at, updated_at)
     VALUES (?, ?, 'home', ?, '[]', 1, 'Nossas memórias', 1, 'arc', ?, ?)`,
    [crypto.randomUUID(), tenant.id, JSON.stringify(homeEvents), timestamp, timestamp],
  );
  await execute(
    c.env.DB,
    `INSERT INTO notas (id, tenant_id, titulo, conteudo, data, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [
      crypto.randomUUID(),
      tenant.id,
      'Filme de sexta',
      'Escolher juntos depois do jantar.',
      timestamp,
      timestamp,
      timestamp,
    ],
  );
  await execute(
    c.env.DB,
    `INSERT INTO cartas (id, tenant_id, tipo, titulo, conteudo, data, created_at, updated_at)
     VALUES (?, ?, 'letter', ?, ?, ?, ?, ?)`,
    [
      crypto.randomUUID(),
      tenant.id,
      'Para os dias corridos',
      'Mesmo quando o dia passa depressa, esta família continua sendo o nosso lugar.',
      timestamp,
      timestamp,
      timestamp,
    ],
  );
  const listId = crypto.randomUUID();
  await execute(
    c.env.DB,
    `INSERT INTO family_lists (id, tenant_id, title, description, created_by, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [
      listId,
      tenant.id,
      'Fim de semana',
      'O que queremos fazer juntos',
      user.id,
      timestamp,
      timestamp,
    ],
  );
  for (const text of ['Preparar o café sem pressa', 'Escolher uma foto para o álbum']) {
    await execute(
      c.env.DB,
      `INSERT INTO family_list_items (id, tenant_id, list_id, text, checked, created_by, created_at, updated_at)
       VALUES (?, ?, ?, ?, 0, ?, ?, ?)`,
      [crypto.randomUUID(), tenant.id, listId, text, user.id, timestamp, timestamp],
    );
  }
  await execute(
    c.env.DB,
    `INSERT INTO quiz_questions (id, tenant_id, question, options, correct_index, active, created_at, updated_at)
     VALUES (?, ?, ?, ?, 0, 1, ?, ?)`,
    [
      crypto.randomUUID(),
      tenant.id,
      'Qual programa combina mais com a família?',
      JSON.stringify(['Filme e pipoca', 'Passeio ao ar livre', 'Cozinhar juntos']),
      timestamp,
      timestamp,
    ],
  );
  await execute(
    c.env.DB,
    `INSERT INTO game_words (id, tenant_id, word, active, created_at, updated_at)
     VALUES (?, ?, ?, 1, ?, ?)`,
    [crypto.randomUUID(), tenant.id, `ABRACO`, timestamp, timestamp],
  );

  const session = await tokenResponse(c.env, user, tenant.id, c.req.header('user-agent'));
  const csrfToken = setSessionCookies(c, c.env, session.accessToken, session.refreshToken);
  c.header('Cache-Control', 'no-store');
  return envelope(c, {
    slug: tenant.slug,
    expiresAt: tenant.expiresAt,
    csrfToken,
  });
});

export { demoRoutes };
