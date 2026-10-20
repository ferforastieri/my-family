import { Hono } from 'hono';
import { z } from 'zod';
import type { AppEnv } from '../env';
import { authMiddleware, requireAccess, requireTenantAdmin } from '../auth';
import { badRequest, envelope, notFound, paginated, parseBody, queryInt } from '../http';
import { execute, iso, jsonArray, now, queryAll, queryOne } from '../db';

const miniTypes = ['memory_match', 'love_order', 'this_or_that'] as const;

interface QuestionRow {
  id: string;
  question: string;
  options: string;
  correct_index: number;
  active: number;
  created_at: number;
  updated_at: number;
}

interface WordRow {
  id: string;
  word: string;
  active: number;
  created_at: number;
  updated_at: number;
}

interface MiniRow {
  id: string;
  type: string;
  title: string;
  instructions: string;
  items: string;
  active: number;
  created_at: number;
  updated_at: number;
}

interface CompletionRow {
  id: string;
  game: string;
  player_name: string;
  user_id: string | null;
  score: number | null;
  total: number | null;
  created_at: number;
}

function questionDto(row: QuestionRow) {
  return {
    id: row.id,
    question: row.question,
    options: jsonArray(row.options),
    correctIndex: row.correct_index,
    active: row.active === 1,
    createdAt: iso(row.created_at),
    updatedAt: iso(row.updated_at),
  };
}

function wordDto(row: WordRow) {
  return {
    id: row.id,
    word: row.word,
    active: row.active === 1,
    createdAt: iso(row.created_at),
    updatedAt: iso(row.updated_at),
  };
}

function miniDto(row: MiniRow) {
  return {
    id: row.id,
    type: row.type,
    title: row.title,
    instructions: row.instructions,
    items: jsonArray(row.items),
    active: row.active === 1,
    createdAt: iso(row.created_at),
    updatedAt: iso(row.updated_at),
  };
}

function completionDto(row: CompletionRow) {
  return {
    id: row.id,
    game: row.game,
    playerName: row.player_name,
    userId: row.user_id,
    score: row.score,
    total: row.total,
    createdAt: iso(row.created_at),
  };
}

const questionSchema = z.object({
  question: z.string(),
  options: z.array(z.string()),
  correctIndex: z.number(),
  active: z.boolean().optional(),
});

const wordSchema = z.object({
  word: z.string(),
  active: z.boolean().optional(),
});

const miniSchema = z.object({
  type: z.enum(miniTypes),
  title: z.string(),
  instructions: z.string().optional(),
  items: z.array(z.string()),
  active: z.boolean().optional(),
});

const completionSchema = z.object({
  game: z.string(),
  playerName: z.string().optional(),
  score: z.number().optional(),
  total: z.number().optional(),
});

function normalizeWord(value: string) {
  return value
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-zA-Z]/g, '')
    .toUpperCase();
}

async function seedQuestions(env: AppEnv['Bindings'], tenantId: string) {
  const count = await queryOne<{ count: number }>(
    env.DB,
    'SELECT COUNT(*) AS count FROM quiz_questions WHERE tenant_id = ?',
    [tenantId],
  );
  if ((count?.count ?? 0) > 0) return;
  const defaults = [
    ['Onde nosso amor mora primeiro?', ['No cuidado', 'Na pressa', 'No silêncio frio']],
    ['Qual é o melhor plano para a família?', ['Crescer juntos', 'Competir sempre', 'Ficar distante']],
    ['O que deixa uma casa mais parecida com lar?', ['Amor e fé', 'Só móveis novos', 'Barulho']],
  ];
  const timestamp = now();
  for (const [question, options] of defaults) {
    await execute(
      env.DB,
      `INSERT INTO quiz_questions (id, tenant_id, question, options, correct_index, active, created_at, updated_at)
       VALUES (?, ?, ?, ?, 0, 1, ?, ?)`,
      [crypto.randomUUID(), tenantId, question, JSON.stringify(options), timestamp, timestamp],
    );
  }
}

async function seedWords(env: AppEnv['Bindings'], tenantId: string) {
  const count = await queryOne<{ count: number }>(
    env.DB,
    'SELECT COUNT(*) AS count FROM game_words WHERE tenant_id = ?',
    [tenantId],
  );
  if ((count?.count ?? 0) > 0) return;
  const timestamp = now();
  for (const word of ['FAMILIA', 'AMOR', 'LAR', 'UNIAO', 'MEMORIA', 'ALEGRIA', 'CARINHO', 'ABRACO', 'SORRISO', 'PASSEIO', 'FESTA']) {
    await execute(
      env.DB,
      `INSERT OR IGNORE INTO game_words (id, tenant_id, word, active, created_at, updated_at)
       VALUES (?, ?, ?, 1, ?, ?)`,
      [crypto.randomUUID(), tenantId, word, timestamp, timestamp],
    );
  }
}

async function seedMiniGames(env: AppEnv['Bindings'], tenantId: string) {
  const count = await queryOne<{ count: number }>(
    env.DB,
    'SELECT COUNT(*) AS count FROM mini_game_configs WHERE tenant_id = ?',
    [tenantId],
  );
  if ((count?.count ?? 0) > 0) return;
  const defaults = [
    {
      type: 'memory_match',
      title: 'Memória da Família',
      instructions: 'Encontre os pares de lembranças iguais.',
      items: ['Amor', 'Abraço', 'Passeio', 'Filme', 'Festa', 'Família'],
    },
    {
      type: 'love_order',
      title: 'Linha do Amor',
      instructions: 'Toque nos momentos na ordem certa da história.',
      items: ['Primeira conversa', 'Primeiro encontro', 'Namoro', 'Casamento', 'Nossa família'],
    },
    {
      type: 'this_or_that',
      title: 'Isso ou Aquilo',
      instructions:
        'Escolha uma opção em cada rodada. Não existe certo ou errado: é sobre preferências da família.',
      items: [
        'Programa perfeito|Shopping|Filme no sofá',
        'Pipoca|Doce|Salgada',
        'Fim de semana|Sair para passear|Ficar em casa juntinhos',
        'Noite ideal|Conversar até tarde|Ver uma série',
        'Passeio em família|Parque|Cinema',
      ],
    },
  ];
  const timestamp = now();
  for (const game of defaults) {
    await execute(
      env.DB,
      `INSERT INTO mini_game_configs (id, tenant_id, type, title, instructions, items, active, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, 1, ?, ?)`,
      [
        crypto.randomUUID(),
        tenantId,
        game.type,
        game.title,
        game.instructions,
        JSON.stringify(game.items),
        timestamp,
        timestamp,
      ],
    );
  }
}

const gamesRoutes = new Hono<AppEnv>();
gamesRoutes.use('*', authMiddleware, requireAccess('jogos'));

gamesRoutes.get('/quiz', async (c) => {
  const principal = c.get('principal');
  await seedQuestions(c.env, principal.tenantId);
  const page = queryInt(c.req.query('page'), 1, 100000);
  const limit = Math.min(100, queryInt(c.req.query('limit'), 20, 100));
  const [rows, total] = await Promise.all([
    queryAll<QuestionRow>(
      c.env.DB,
      'SELECT * FROM quiz_questions WHERE tenant_id = ? AND active = 1 ORDER BY created_at DESC LIMIT ? OFFSET ?',
      [principal.tenantId, limit, (page - 1) * limit],
    ),
    queryOne<{ count: number }>(
      c.env.DB,
      'SELECT COUNT(*) AS count FROM quiz_questions WHERE tenant_id = ? AND active = 1',
      [principal.tenantId],
    ),
  ]);
  return envelope(c, paginated(rows.map(questionDto), total?.count ?? 0, page, limit));
});

gamesRoutes.get('/quiz/admin', requireTenantAdmin, async (c) => {
  const principal = c.get('principal');
  await seedQuestions(c.env, principal.tenantId);
  const page = queryInt(c.req.query('page'), 1, 100000);
  const limit = Math.min(100, queryInt(c.req.query('limit'), 20, 100));
  const [rows, total] = await Promise.all([
    queryAll<QuestionRow>(
      c.env.DB,
      'SELECT * FROM quiz_questions WHERE tenant_id = ? ORDER BY created_at DESC LIMIT ? OFFSET ?',
      [principal.tenantId, limit, (page - 1) * limit],
    ),
    queryOne<{ count: number }>(
      c.env.DB,
      'SELECT COUNT(*) AS count FROM quiz_questions WHERE tenant_id = ?',
      [principal.tenantId],
    ),
  ]);
  return envelope(c, paginated(rows.map(questionDto), total?.count ?? 0, page, limit));
});

gamesRoutes.post('/quiz', requireTenantAdmin, async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(c, questionSchema);
  const question = body.question.trim();
  const options = body.options.map((option) => option.trim()).filter(Boolean);
  if (!question || !options.length) throw badRequest('Preencha a pergunta e as opções.');
  const id = crypto.randomUUID();
  const timestamp = now();
  await execute(
    c.env.DB,
    `INSERT INTO quiz_questions (id, tenant_id, question, options, correct_index, active, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      id,
      principal.tenantId,
      question,
      JSON.stringify(options),
      body.correctIndex,
      body.active === false ? 0 : 1,
      timestamp,
      timestamp,
    ],
  );
  const row = (await queryOne<QuestionRow>(
    c.env.DB,
    'SELECT * FROM quiz_questions WHERE id = ?',
    [id],
  ))!;
  return envelope(c, { message: 'Pergunta salva.', ...questionDto(row) });
});

gamesRoutes.put('/quiz/:id', requireTenantAdmin, async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(c, questionSchema.partial());
  const sets: string[] = [];
  const params: unknown[] = [];
  if (body.question !== undefined) {
    const value = body.question.trim();
    if (!value) throw badRequest('Preencha a pergunta.');
    sets.push('question = ?');
    params.push(value);
  }
  if (body.options !== undefined) {
    const options = body.options.map((option) => option.trim()).filter(Boolean);
    if (!options.length) throw badRequest('Preencha as opções.');
    sets.push('options = ?');
    params.push(JSON.stringify(options));
  }
  if (body.correctIndex !== undefined) {
    sets.push('correct_index = ?');
    params.push(body.correctIndex);
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
      `UPDATE quiz_questions SET ${sets.join(', ')} WHERE tenant_id = ? AND id = ?`,
      params,
    );
  }
  const row = await queryOne<QuestionRow>(
    c.env.DB,
    'SELECT * FROM quiz_questions WHERE tenant_id = ? AND id = ?',
    [principal.tenantId, c.req.param('id')],
  );
  return envelope(c, row ? { message: 'Pergunta atualizada.', ...questionDto(row) } : null);
});

gamesRoutes.delete('/quiz/:id', requireTenantAdmin, async (c) => {
  const principal = c.get('principal');
  const result = await execute(
    c.env.DB,
    'DELETE FROM quiz_questions WHERE tenant_id = ? AND id = ?',
    [principal.tenantId, c.req.param('id')],
  );
  return envelope(c, { ok: result.meta.changes === 1, message: 'Pergunta removida.' });
});

gamesRoutes.get('/words', async (c) => {
  const principal = c.get('principal');
  await seedWords(c.env, principal.tenantId);
  const page = queryInt(c.req.query('page'), 1, 100000);
  const limit = Math.min(100, queryInt(c.req.query('limit'), 20, 100));
  const [rows, total] = await Promise.all([
    queryAll<WordRow>(
      c.env.DB,
      'SELECT * FROM game_words WHERE tenant_id = ? AND active = 1 ORDER BY word ASC LIMIT ? OFFSET ?',
      [principal.tenantId, limit, (page - 1) * limit],
    ),
    queryOne<{ count: number }>(
      c.env.DB,
      'SELECT COUNT(*) AS count FROM game_words WHERE tenant_id = ? AND active = 1',
      [principal.tenantId],
    ),
  ]);
  return envelope(c, paginated(rows.map(wordDto), total?.count ?? 0, page, limit));
});

gamesRoutes.get('/words/admin', requireTenantAdmin, async (c) => {
  const principal = c.get('principal');
  await seedWords(c.env, principal.tenantId);
  const page = queryInt(c.req.query('page'), 1, 100000);
  const limit = Math.min(100, queryInt(c.req.query('limit'), 20, 100));
  const [rows, total] = await Promise.all([
    queryAll<WordRow>(
      c.env.DB,
      'SELECT * FROM game_words WHERE tenant_id = ? ORDER BY word ASC LIMIT ? OFFSET ?',
      [principal.tenantId, limit, (page - 1) * limit],
    ),
    queryOne<{ count: number }>(
      c.env.DB,
      'SELECT COUNT(*) AS count FROM game_words WHERE tenant_id = ?',
      [principal.tenantId],
    ),
  ]);
  return envelope(c, paginated(rows.map(wordDto), total?.count ?? 0, page, limit));
});

gamesRoutes.post('/words', requireTenantAdmin, async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(c, wordSchema);
  const word = normalizeWord(body.word);
  if (!word) throw badRequest('Palavra inválida.');
  const id = crypto.randomUUID();
  const timestamp = now();
  await execute(
    c.env.DB,
    `INSERT INTO game_words (id, tenant_id, word, active, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [id, principal.tenantId, word, body.active === false ? 0 : 1, timestamp, timestamp],
  );
  const row = (await queryOne<WordRow>(c.env.DB, 'SELECT * FROM game_words WHERE id = ?', [id]))!;
  return envelope(c, { message: 'Palavra salva.', ...wordDto(row) });
});

gamesRoutes.put('/words/:id', requireTenantAdmin, async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(c, wordSchema.partial());
  const sets: string[] = [];
  const params: unknown[] = [];
  if (body.word !== undefined) {
    const word = normalizeWord(body.word);
    if (!word) throw badRequest('Palavra inválida.');
    sets.push('word = ?');
    params.push(word);
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
      `UPDATE game_words SET ${sets.join(', ')} WHERE tenant_id = ? AND id = ?`,
      params,
    );
  }
  const row = await queryOne<WordRow>(
    c.env.DB,
    'SELECT * FROM game_words WHERE tenant_id = ? AND id = ?',
    [principal.tenantId, c.req.param('id')],
  );
  return envelope(c, row ? { message: 'Palavra atualizada.', ...wordDto(row) } : null);
});

gamesRoutes.delete('/words/:id', requireTenantAdmin, async (c) => {
  const principal = c.get('principal');
  const result = await execute(
    c.env.DB,
    'DELETE FROM game_words WHERE tenant_id = ? AND id = ?',
    [principal.tenantId, c.req.param('id')],
  );
  return envelope(c, { ok: result.meta.changes === 1, message: 'Palavra removida.' });
});

gamesRoutes.get('/mini', async (c) => {
  const principal = c.get('principal');
  await seedMiniGames(c.env, principal.tenantId);
  const page = queryInt(c.req.query('page'), 1, 100000);
  const limit = Math.min(100, queryInt(c.req.query('limit'), 20, 100));
  const [rows, total] = await Promise.all([
    queryAll<MiniRow>(
      c.env.DB,
      'SELECT * FROM mini_game_configs WHERE tenant_id = ? AND active = 1 ORDER BY created_at ASC LIMIT ? OFFSET ?',
      [principal.tenantId, limit, (page - 1) * limit],
    ),
    queryOne<{ count: number }>(
      c.env.DB,
      'SELECT COUNT(*) AS count FROM mini_game_configs WHERE tenant_id = ? AND active = 1',
      [principal.tenantId],
    ),
  ]);
  return envelope(c, paginated(rows.map(miniDto), total?.count ?? 0, page, limit));
});

gamesRoutes.get('/mini/admin', requireTenantAdmin, async (c) => {
  const principal = c.get('principal');
  await seedMiniGames(c.env, principal.tenantId);
  const page = queryInt(c.req.query('page'), 1, 100000);
  const limit = Math.min(100, queryInt(c.req.query('limit'), 20, 100));
  const [rows, total] = await Promise.all([
    queryAll<MiniRow>(
      c.env.DB,
      'SELECT * FROM mini_game_configs WHERE tenant_id = ? ORDER BY created_at ASC LIMIT ? OFFSET ?',
      [principal.tenantId, limit, (page - 1) * limit],
    ),
    queryOne<{ count: number }>(
      c.env.DB,
      'SELECT COUNT(*) AS count FROM mini_game_configs WHERE tenant_id = ?',
      [principal.tenantId],
    ),
  ]);
  return envelope(c, paginated(rows.map(miniDto), total?.count ?? 0, page, limit));
});

gamesRoutes.post('/mini', requireTenantAdmin, async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(c, miniSchema);
  const title = body.title.trim();
  const items = body.items.map((item) => item.trim()).filter(Boolean);
  if (!title || !items.length) throw badRequest('Preencha o título e os itens.');
  const id = crypto.randomUUID();
  const timestamp = now();
  await execute(
    c.env.DB,
    `INSERT INTO mini_game_configs (id, tenant_id, type, title, instructions, items, active, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      id,
      principal.tenantId,
      body.type,
      title,
      body.instructions?.trim() ?? '',
      JSON.stringify(items),
      body.active === false ? 0 : 1,
      timestamp,
      timestamp,
    ],
  );
  const row = (await queryOne<MiniRow>(
    c.env.DB,
    'SELECT * FROM mini_game_configs WHERE id = ?',
    [id],
  ))!;
  return envelope(c, { message: 'Mini jogo salvo.', ...miniDto(row) });
});

gamesRoutes.put('/mini/:id', requireTenantAdmin, async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(c, miniSchema.partial());
  const sets: string[] = [];
  const params: unknown[] = [];
  if (body.type !== undefined) {
    sets.push('type = ?');
    params.push(body.type);
  }
  if (body.title !== undefined) {
    const value = body.title.trim();
    if (!value) throw badRequest('Preencha o título.');
    sets.push('title = ?');
    params.push(value);
  }
  if (body.instructions !== undefined) {
    sets.push('instructions = ?');
    params.push(body.instructions.trim());
  }
  if (body.items !== undefined) {
    const items = body.items.map((item) => item.trim()).filter(Boolean);
    if (!items.length) throw badRequest('Preencha os itens.');
    sets.push('items = ?');
    params.push(JSON.stringify(items));
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
      `UPDATE mini_game_configs SET ${sets.join(', ')} WHERE tenant_id = ? AND id = ?`,
      params,
    );
  }
  const row = await queryOne<MiniRow>(
    c.env.DB,
    'SELECT * FROM mini_game_configs WHERE tenant_id = ? AND id = ?',
    [principal.tenantId, c.req.param('id')],
  );
  return envelope(c, row ? { message: 'Mini jogo atualizado.', ...miniDto(row) } : null);
});

gamesRoutes.delete('/mini/:id', requireTenantAdmin, async (c) => {
  const principal = c.get('principal');
  const result = await execute(
    c.env.DB,
    'DELETE FROM mini_game_configs WHERE tenant_id = ? AND id = ?',
    [principal.tenantId, c.req.param('id')],
  );
  return envelope(c, { ok: result.meta.changes === 1, message: 'Mini jogo removido.' });
});

gamesRoutes.post('/complete', async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(c, completionSchema);
  if (!body.game?.trim()) throw badRequest('Jogo inválido.');
  const playerName = principal.name || principal.email || body.playerName?.trim() || 'Visitante';
  const id = crypto.randomUUID();
  const timestamp = now();
  await execute(
    c.env.DB,
    `INSERT INTO game_completions (id, tenant_id, game, player_name, user_id, score, total, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      id,
      principal.tenantId,
      body.game.trim(),
      playerName,
      principal.id,
      body.score ?? null,
      body.total ?? null,
      timestamp,
    ],
  );
  const row = (await queryOne<CompletionRow>(
    c.env.DB,
    'SELECT * FROM game_completions WHERE id = ?',
    [id],
  ))!;
  return envelope(c, { message: 'Jogo concluído.', ...completionDto(row) });
});

gamesRoutes.get('/stats', requireTenantAdmin, async (c) => {
  const principal = c.get('principal');
  const page = queryInt(c.req.query('page'), 1, 100000);
  const limit = Math.min(100, queryInt(c.req.query('limit'), 20, 100));
  const [rows, total] = await Promise.all([
    queryAll<{
      game: string;
      player_name: string;
      count: number;
      best_score: number | null;
      last_at: number;
    }>(
      c.env.DB,
      `SELECT game, player_name, COUNT(*) AS count, MAX(score) AS best_score, MAX(created_at) AS last_at
         FROM game_completions WHERE tenant_id = ?
        GROUP BY game, player_name
        ORDER BY game ASC, count DESC, last_at DESC
        LIMIT ? OFFSET ?`,
      [principal.tenantId, limit, (page - 1) * limit],
    ),
    queryOne<{ count: number }>(
      c.env.DB,
      `SELECT COUNT(*) AS count FROM (
         SELECT 1 FROM game_completions WHERE tenant_id = ? GROUP BY game, player_name
       )`,
      [principal.tenantId],
    ),
  ]);
  return envelope(
    c,
    paginated(
      rows.map((row) => ({
        game: row.game,
        playerName: row.player_name,
        count: row.count,
        bestScore: row.best_score,
        lastAt: row.last_at,
      })),
      total?.count ?? 0,
      page,
      limit,
    ),
  );
});

export { gamesRoutes };
