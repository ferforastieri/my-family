import type { Env } from './env';
import { execute, jsonArray, now, queryAll, queryOne } from './db';
import {
  hashToken,
  loadPrincipal,
  normalizeAccessKeys,
  randomToken,
  signAccessToken,
  type MembershipRole,
  type Principal,
  type TenantEntity,
  type UserAccessKey,
  type UserRole,
} from './auth';
import { badRequest, conflict, forbidden, notFound } from './http';
import { invalidPhoneNumber, sendInvitation, type PhoneChannel } from './messaging';

const reservedSlugs = new Set([
  'api',
  'app',
  'admin',
  'painel',
  'demo',
  'public',
  'www',
  'ajuda',
  'suporte',
]);

export interface TenantRow {
  id: string;
  name: string;
  slug: string;
  status: string;
  plan_code: string;
  subscription_status: string;
  theme: string;
  is_demo: number;
  expires_at: number | null;
  created_at: number;
  updated_at: number;
}

export interface MembershipRow {
  id: string;
  tenant_id: string;
  user_id: string;
  role: string;
  relationship: string;
  access: string;
  created_at: number;
  updated_at: number;
}

export function tenantFromRow(row: TenantRow): TenantEntity {
  let theme = { primaryColor: '#9F4D4D', fontFamily: 'nunitoSans' };
  try {
    theme = { ...theme, ...JSON.parse(row.theme) };
  } catch {
    // keep defaults
  }
  return {
    id: row.id,
    name: row.name,
    slug: row.slug,
    status: row.status as TenantEntity['status'],
    planCode: row.plan_code,
    subscriptionStatus: row.subscription_status as TenantEntity['subscriptionStatus'],
    theme,
    isDemo: row.is_demo === 1,
    expiresAt: row.expires_at ? new Date(row.expires_at).toISOString() : null,
    createdAt: new Date(row.created_at).toISOString(),
    updatedAt: new Date(row.updated_at).toISOString(),
  };
}

export function normalizeSlug(value: string): string {
  const slug = value?.trim().toLowerCase();
  if (!/^[a-z0-9][a-z0-9-]{1,46}[a-z0-9]$/.test(slug) || reservedSlugs.has(slug)) {
    throw badRequest('Endereço da família inválido ou reservado.');
  }
  return slug;
}

export async function findTenantById(env: Env, id: string): Promise<TenantEntity | null> {
  const row = await queryOne<TenantRow>(env.DB, 'SELECT * FROM tenants WHERE id = ?', [id]);
  return row ? tenantFromRow(row) : null;
}

export async function findTenantBySlug(env: Env, slug: string): Promise<TenantEntity | null> {
  const row = await queryOne<TenantRow>(env.DB, 'SELECT * FROM tenants WHERE slug = ?', [
    slug.toLowerCase(),
  ]);
  return row ? tenantFromRow(row) : null;
}

export async function createTenant(
  env: Env,
  data: { name: string; slug: string; isDemo?: boolean; expiresAt?: Date },
): Promise<TenantEntity> {
  const id = crypto.randomUUID();
  const timestamp = now();
  await execute(
    env.DB,
    `INSERT INTO tenants (id, name, slug, status, plan_code, subscription_status, theme, is_demo, expires_at, created_at, updated_at)
     VALUES (?, ?, ?, 'active', ?, 'active', ?, ?, ?, ?, ?)`,
    [
      id,
      data.name,
      data.slug,
      data.isDemo ? 'demo' : 'early_access',
      '{"primaryColor":"#9F4D4D","fontFamily":"nunitoSans"}',
      data.isDemo ? 1 : 0,
      data.expiresAt ? data.expiresAt.getTime() : null,
      timestamp,
      timestamp,
    ],
  );
  return (await findTenantById(env, id))!;
}

export async function updateTenant(
  env: Env,
  id: string,
  data: { name?: string; status?: string; theme?: { primaryColor: string; fontFamily: string } },
): Promise<TenantEntity | null> {
  const sets: string[] = [];
  const params: unknown[] = [];
  if (data.name !== undefined) {
    sets.push('name = ?');
    params.push(data.name);
  }
  if (data.status !== undefined) {
    sets.push('status = ?');
    params.push(data.status);
  }
  if (data.theme !== undefined) {
    sets.push('theme = ?');
    params.push(JSON.stringify(data.theme));
  }
  if (sets.length) {
    sets.push('updated_at = ?');
    params.push(now(), id);
    await execute(env.DB, `UPDATE tenants SET ${sets.join(', ')} WHERE id = ?`, params);
  }
  return findTenantById(env, id);
}

const tenantTables = [
  'fotos',
  'musicas',
  'cartas',
  'notas',
  'family_lists',
  'family_list_items',
  'chat_conversations',
  'chat_messages',
  'game_completions',
  'game_words',
  'mini_game_configs',
  'quiz_questions',
  'home_settings',
  'location_updates',
  'location_places',
  'location_presences',
  'notifications',
  'push_subscriptions',
  'scheduled_notifications',
];

export async function deleteTenantData(env: Env, tenantId: string): Promise<void> {
  const statements = tenantTables.map((table) =>
    env.DB.prepare(`DELETE FROM ${table} WHERE tenant_id = ?`).bind(tenantId),
  );
  statements.push(
    env.DB.prepare('DELETE FROM memberships WHERE tenant_id = ?').bind(tenantId),
    env.DB.prepare('DELETE FROM invitations WHERE tenant_id = ?').bind(tenantId),
    env.DB.prepare('DELETE FROM auth_sessions WHERE tenant_id = ?').bind(tenantId),
    env.DB.prepare('DELETE FROM tenants WHERE id = ?').bind(tenantId),
  );
  await env.DB.batch(statements);
}

export async function createMembership(
  env: Env,
  data: {
    tenantId: string;
    userId: string;
    role: MembershipRole;
    relationship?: UserRole;
    access?: UserAccessKey[];
  },
): Promise<void> {
  const timestamp = now();
  await execute(
    env.DB,
    `INSERT INTO memberships (id, tenant_id, user_id, role, relationship, access, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      crypto.randomUUID(),
      data.tenantId,
      data.userId,
      data.role,
      data.relationship ?? 'friends',
      JSON.stringify(data.access ?? []),
      timestamp,
      timestamp,
    ],
  );
}

export async function findMembership(
  env: Env,
  tenantId: string,
  userId: string,
): Promise<MembershipRow | null> {
  return queryOne<MembershipRow>(
    env.DB,
    'SELECT * FROM memberships WHERE tenant_id = ? AND user_id = ?',
    [tenantId, userId],
  );
}

export async function listMembershipsForUser(
  env: Env,
  userId: string,
): Promise<Array<TenantEntity & { membershipRole: MembershipRole; relationship: UserRole; access: UserAccessKey[] }>> {
  const rows = await queryAll<TenantRow & { membership_role: string; relationship: string; membership_access: string }>(
    env.DB,
    `SELECT t.*, m.role AS membership_role, m.relationship, m.access AS membership_access
       FROM memberships m
       JOIN tenants t ON t.id = m.tenant_id
      WHERE m.user_id = ? AND t.status <> 'deleted'
      ORDER BY m.created_at ASC`,
    [userId],
  );
  return rows.map((row) => ({
    ...tenantFromRow(row),
    membershipRole: row.membership_role as MembershipRole,
    relationship: row.relationship as UserRole,
    access: normalizeAccessKeys(jsonArray(row.membership_access)),
  }));
}

export async function createFamily(
  env: Env,
  userId: string,
  name: string,
  rawSlug: string,
): Promise<TenantEntity> {
  const slug = normalizeSlug(rawSlug);
  if (!name?.trim()) throw badRequest('Nome da família é obrigatório.');
  if (await findTenantBySlug(env, slug)) throw conflict('Este endereço já está em uso.');
  const tenant = await createTenant(env, { name: name.trim(), slug });
  try {
    await createMembership(env, {
      tenantId: tenant.id,
      userId,
      role: 'owner',
      relationship: 'friends',
    });
  } catch (error) {
    await deleteTenantData(env, tenant.id);
    throw error;
  }
  return tenant;
}

export async function tenantPrincipal(
  env: Env,
  userId: string,
  tenantId: string,
): Promise<Principal> {
  const principal = await loadPrincipal(env, userId, tenantId);
  if (!principal) throw forbidden('Você não participa desta família.');
  return principal;
}

export async function tenantIdForSlug(
  env: Env,
  userId: string,
  slug?: string,
): Promise<string | undefined> {
  if (!slug) return undefined;
  const tenant = await findTenantBySlug(env, slug);
  if (!tenant) throw notFound('Família não encontrada.');
  await tenantPrincipal(env, userId, tenant.id);
  return tenant.id;
}

export async function members(env: Env, tenantId: string) {
  const rows = await queryAll<MembershipRow & {
    phone_number: string;
    name: string | null;
    avatar_path: string | null;
  }>(
    env.DB,
    `SELECT m.*, u.phone_number, u.name, u.avatar_path
       FROM memberships m
       JOIN users u ON u.id = m.user_id
      WHERE m.tenant_id = ?
      ORDER BY m.created_at ASC`,
    [tenantId],
  );
  return rows.map((row) => ({
    id: row.user_id,
    membershipId: row.id,
    phoneNumber: row.phone_number,
    name: row.name,
    avatarPath: row.avatar_path,
    role: row.relationship as UserRole,
    membershipRole: row.role as MembershipRole,
    access: normalizeAccessKeys(jsonArray(row.access)),
    createdAt: new Date(row.created_at).toISOString(),
  }));
}

export async function member(env: Env, tenantId: string, userId: string) {
  return (await members(env, tenantId)).find((item) => item.id === userId) ?? null;
}

export async function updateMember(
  env: Env,
  tenantId: string,
  actorUserId: string,
  userId: string,
  data: { role?: UserRole; access?: string[]; membershipRole?: MembershipRole },
) {
  const [actor, membership] = await Promise.all([
    findMembership(env, tenantId, actorUserId),
    findMembership(env, tenantId, userId),
  ]);
  if (!actor || !membership) throw notFound('Membro não encontrado.');
  if (membership.role === 'owner' && actor.role !== 'owner') {
    throw forbidden('Somente o owner pode alterar o owner.');
  }
  if (data.membershipRole && actor.role !== 'owner') {
    throw forbidden('Somente o owner pode alterar administradores.');
  }
  if (membership.role === 'owner' && data.membershipRole && data.membershipRole !== 'owner') {
    throw badRequest('Transfira a propriedade antes de alterar o owner.');
  }
  const sets: string[] = [];
  const params: unknown[] = [];
  if (data.role) {
    sets.push('relationship = ?');
    params.push(data.role);
  }
  if (data.access) {
    sets.push('access = ?');
    params.push(JSON.stringify(normalizeAccessKeys(data.access)));
  }
  if (data.membershipRole) {
    sets.push('role = ?');
    params.push(data.membershipRole);
  }
  if (sets.length) {
    sets.push('updated_at = ?');
    params.push(now(), tenantId, userId);
    await execute(
      env.DB,
      `UPDATE memberships SET ${sets.join(', ')} WHERE tenant_id = ? AND user_id = ?`,
      params,
    );
  }
  return member(env, tenantId, userId);
}

export async function removeMember(
  env: Env,
  tenantId: string,
  actorUserId: string,
  userId: string,
): Promise<boolean> {
  const [actor, membership] = await Promise.all([
    findMembership(env, tenantId, actorUserId),
    findMembership(env, tenantId, userId),
  ]);
  if (!actor || !membership) return false;
  if (membership.role === 'owner') throw badRequest('O owner não pode ser removido.');
  if (membership.role === 'admin' && actor.role !== 'owner') {
    throw forbidden('Somente o owner pode remover administradores.');
  }
  await execute(env.DB, 'DELETE FROM memberships WHERE tenant_id = ? AND user_id = ?', [
    tenantId,
    userId,
  ]);
  return true;
}

export interface InvitationRow {
  id: string;
  tenant_id: string;
  phone_number: string;
  channel: string;
  role: string;
  relationship: string;
  access: string;
  token_hash: string;
  expires_at: number;
  status: string;
  invited_by: string | null;
  created_at: number;
}

export async function invite(
  env: Env,
  tenantId: string,
  invitedBy: string,
  input: {
    phone: string;
    channel?: PhoneChannel;
    role?: MembershipRole;
    relationship?: UserRole;
    access?: string[];
  },
) {
  const phoneNumber = invalidPhoneNumber(env, input.phone);
  if (!phoneNumber) throw badRequest('Celular inválido.');
  if (input.role === 'owner') throw badRequest('O papel owner não pode ser convidado.');
  const token = randomToken(32);
  const expiresAt = Date.now() + 7 * 24 * 60 * 60 * 1000;
  const id = crypto.randomUUID();
  const timestamp = now();
  await execute(
    env.DB,
    `INSERT INTO invitations (id, tenant_id, phone_number, channel, role, relationship, access, token_hash, expires_at, status, invited_by, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', ?, ?, ?)`,
    [
      id,
      tenantId,
      phoneNumber,
      input.channel ?? 'sms',
      input.role ?? 'member',
      input.relationship ?? 'friends',
      JSON.stringify(normalizeAccessKeys(input.access)),
      await hashToken(token),
      expiresAt,
      invitedBy,
      timestamp,
      timestamp,
    ],
  );
  const tenant = await findTenantById(env, tenantId);
  try {
    await sendInvitation(
      env,
      phoneNumber,
      tenant?.name ?? 'uma família',
      token,
      input.channel ?? 'sms',
    );
  } catch {
    // O convite continua válido e pode ser reenviado.
  }
  return {
    id,
    phoneNumber,
    channel: input.channel ?? 'sms',
    role: input.role ?? 'member',
    expiresAt: new Date(expiresAt).toISOString(),
    token,
  };
}

export async function listInvitations(env: Env, tenantId: string) {
  const rows = await queryAll<InvitationRow>(
    env.DB,
    `SELECT * FROM invitations
      WHERE tenant_id = ? AND status = 'pending' AND expires_at > ?
      ORDER BY created_at DESC`,
    [tenantId, now()],
  );
  return rows.map((row) => ({
    id: row.id,
    phoneNumber: row.phone_number,
    channel: row.channel,
    role: row.role,
    relationship: row.relationship,
    access: normalizeAccessKeys(jsonArray(row.access)),
    status: row.status,
    expiresAt: new Date(row.expires_at).toISOString(),
    invitedBy: row.invited_by,
    createdAt: new Date(row.created_at).toISOString(),
  }));
}

export async function revokeInvitation(env: Env, tenantId: string, id: string) {
  const result = await execute(
    env.DB,
    `UPDATE invitations SET status = 'revoked', updated_at = ? WHERE id = ? AND tenant_id = ?`,
    [now(), id, tenantId],
  );
  return result.meta.changes === 1;
}

export async function acceptInvitation(env: Env, userId: string, rawToken: string) {
  const invitation = await queryOne<InvitationRow>(
    env.DB,
    `SELECT * FROM invitations WHERE token_hash = ? AND status = 'pending' AND expires_at > ?`,
    [await hashToken(rawToken), now()],
  );
  if (!invitation) throw badRequest('Convite inválido ou expirado.');
  const user = await queryOne<{ phone_number: string }>(
    env.DB,
    'SELECT phone_number FROM users WHERE id = ?',
    [userId],
  );
  if (!user || user.phone_number !== invitation.phone_number) {
    throw forbidden('Este convite pertence a outro celular.');
  }
  const existing = await findMembership(env, invitation.tenant_id, userId);
  if (!existing) {
    await createMembership(env, {
      tenantId: invitation.tenant_id,
      userId,
      role: invitation.role as MembershipRole,
      relationship: invitation.relationship as UserRole,
      access: normalizeAccessKeys(jsonArray(invitation.access)),
    });
  }
  await execute(
    env.DB,
    `UPDATE invitations SET status = 'accepted', accepted_at = ?, updated_at = ? WHERE id = ?`,
    [now(), now(), invitation.id],
  );
  return findTenantById(env, invitation.tenant_id);
}

export async function createSession(
  env: Env,
  data: {
    userId: string;
    tokenHash: string;
    tenantId?: string;
    userAgent?: string;
    expiresAt: number;
  },
): Promise<void> {
  await execute(
    env.DB,
    `INSERT INTO auth_sessions (id, user_id, token_hash, tenant_id, user_agent, expires_at, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [
      crypto.randomUUID(),
      data.userId,
      data.tokenHash,
      data.tenantId ?? null,
      data.userAgent ?? null,
      data.expiresAt,
      now(),
    ],
  );
}

export async function consumeSession(
  env: Env,
  tokenHash: string,
): Promise<{ user_id: string; tenant_id: string | null } | null> {
  return queryOne<{ user_id: string; tenant_id: string | null }>(
    env.DB,
    `UPDATE auth_sessions
        SET revoked_at = ?
      WHERE token_hash = ? AND revoked_at IS NULL AND expires_at > ?
      RETURNING user_id, tenant_id`,
    [now(), tokenHash, now()],
  );
}

export async function revokeSession(env: Env, tokenHash: string): Promise<void> {
  await execute(
    env.DB,
    'UPDATE auth_sessions SET revoked_at = ? WHERE token_hash = ? AND revoked_at IS NULL',
    [now(), tokenHash],
  );
}

export interface SessionResult {
  accessToken: string;
  refreshToken: string;
  user: unknown;
  tenant: TenantEntity | null;
  tenants: unknown[];
}

export async function tokenResponse(
  env: Env,
  user: {
    id: string;
    phoneNumber: string;
    name: string | null;
    role: UserRole;
    access: UserAccessKey[];
    avatarPath: string | null;
    platformRole: 'super_admin' | null;
  },
  tenantId?: string,
  userAgent?: string,
): Promise<SessionResult> {
  const memberships = await listMembershipsForUser(env, user.id);
  const selectedTenantId =
    tenantId ?? (memberships.length === 1 ? memberships[0].id : undefined);
  const principal = selectedTenantId
    ? await loadPrincipal(env, user.id, selectedTenantId)
    : null;
  const accessToken = await signAccessToken(env, user.id, selectedTenantId);
  const refreshToken = randomToken(48);
  await createSession(env, {
    userId: user.id,
    tokenHash: await hashToken(refreshToken),
    tenantId: selectedTenantId,
    userAgent,
    expiresAt: Date.now() + 90 * 24 * 60 * 60 * 1000,
  });
  return {
    accessToken,
    refreshToken,
    user: principal ?? {
      id: user.id,
      phoneNumber: user.phoneNumber,
      name: user.name,
      role: user.role,
      access: user.access,
      avatarPath: user.avatarPath,
      platformRole: user.platformRole,
    },
    tenant: principal?.tenant ?? null,
    tenants: memberships,
  };
}
